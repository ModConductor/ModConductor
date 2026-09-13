#include "my_application.h"

#include <fcntl.h>
#include <flutter_linux/flutter_linux.h>
#include <sys/file.h>
#include <sys/stat.h>
#include <unistd.h>

#include "desktop_channel.h"
#ifdef GDK_WINDOWING_X11
#include <gdk/gdkx.h>
#endif

#include "flutter/generated_plugin_registrant.h"

struct _MyApplication {
  GtkApplication parent_instance;
  GtkWindow* window;
  DesktopChannel* desktop;
  int lease;
  bool closing;
};

G_DEFINE_TYPE(MyApplication, my_application, GTK_TYPE_APPLICATION)

// Called when first Flutter frame received.
static void first_frame_cb(MyApplication* self, FlView* view) {
  gtk_widget_show(gtk_widget_get_toplevel(GTK_WIDGET(view)));
}

// Implements GApplication::activate.
static void my_application_activate(GApplication* application) {
  MyApplication* self = MY_APPLICATION(application);
  if (!self->desktop || self->closing) return;
  if (self->window) {
    gtk_window_present(self->window);
    return;
  }
  GtkWindow* window =
      GTK_WINDOW(gtk_application_window_new(GTK_APPLICATION(application)));
  self->window = window;
  g_signal_connect_swapped(
      window, "destroy",
      G_CALLBACK(+[](MyApplication* app) { app->closing = true; }), self);
  g_object_add_weak_pointer(G_OBJECT(window),
                            reinterpret_cast<gpointer*>(&self->window));

  // Use a header bar when running in GNOME as this is the common style used
  // by applications and is the setup most users will be using (e.g. Ubuntu
  // desktop).
  // If running on X and not using GNOME then just use a traditional title bar
  // in case the window manager does more exotic layout, e.g. tiling.
  // If running on Wayland assume the header bar will work (may need changing
  // if future cases occur).
  gboolean use_header_bar = TRUE;
#ifdef GDK_WINDOWING_X11
  GdkScreen* screen = gtk_window_get_screen(window);
  if (GDK_IS_X11_SCREEN(screen)) {
    const gchar* wm_name = gdk_x11_screen_get_window_manager_name(screen);
    if (g_strcmp0(wm_name, "GNOME Shell") != 0) {
      use_header_bar = FALSE;
    }
  }
#endif
  if (use_header_bar) {
    GtkHeaderBar* header_bar = GTK_HEADER_BAR(gtk_header_bar_new());
    gtk_widget_show(GTK_WIDGET(header_bar));
    gtk_header_bar_set_title(header_bar, "Mod Conductor");
    gtk_header_bar_set_show_close_button(header_bar, TRUE);
    gtk_window_set_titlebar(window, GTK_WIDGET(header_bar));
  } else {
    gtk_window_set_title(window, "Mod Conductor");
  }

  gtk_window_set_default_size(window, 1280, 720);

  g_autoptr(FlDartProject) project = fl_dart_project_new();

  FlView* view = fl_view_new(project);
  GdkRGBA background_color;
  // Background defaults to black, override it here if necessary, e.g. #00000000
  // for transparent.
  gdk_rgba_parse(&background_color, "#000000");
  fl_view_set_background_color(view, &background_color);
  gtk_widget_show(GTK_WIDGET(view));
  gtk_container_add(GTK_CONTAINER(window), GTK_WIDGET(view));

  // Show the window when Flutter renders.
  // Requires the view to be realized so we can start rendering.
  g_signal_connect_swapped(view, "first-frame", G_CALLBACK(first_frame_cb),
                           self);
  gtk_widget_realize(GTK_WIDGET(view));

  self->desktop->Attach(
      fl_engine_get_binary_messenger(fl_view_get_engine(view)));
  fl_register_plugins(FL_PLUGIN_REGISTRY(view));

  gtk_widget_grab_focus(GTK_WIDGET(view));
}

static int my_application_command_line(GApplication* application,
                                       GApplicationCommandLine* command) {
  auto* self = MY_APPLICATION(application);
  g_auto(GStrv) values =
      g_application_command_line_get_arguments(command, nullptr);
  desktop::Arguments args;
  for (int i = 1; values[i]; ++i) {
    if (!g_utf8_validate(values[i], -1, nullptr)) {
      args = {"--invalid-request"};
      break;
    }
    args.emplace_back(values[i]);
  }
  if (!self->desktop || self->closing || !self->desktop->Add(args)) {
    g_application_command_line_printerr(
        command,
        "Mod Conductor cannot accept this request. Use the open window.\n");
    return 1;
  }
  g_application_activate(application);
  return 0;
}

// Implements GApplication::startup.
static void my_application_startup(GApplication* application) {
  G_APPLICATION_CLASS(my_application_parent_class)->startup(application);
  auto* self = MY_APPLICATION(application);
  const char* runtime = g_getenv("XDG_RUNTIME_DIR");
  struct stat facts;
  if (!runtime || lstat(runtime, &facts) != 0 || !S_ISDIR(facts.st_mode) ||
      facts.st_uid != getuid() || (facts.st_mode & 077) != 0)
    return;
  g_autofree gchar* path =
      g_build_filename(runtime, "mod-conductor-desktop.lock", nullptr);
  self->lease = open(path, O_CREAT | O_RDWR | O_CLOEXEC | O_NOFOLLOW, 0600);
  if (self->lease < 0) return;
  if (flock(self->lease, LOCK_EX | LOCK_NB) != 0) {
    close(self->lease);
    self->lease = -1;
    return;
  }
  self->desktop = new DesktopChannel(
      g_application_get_dbus_connection(application) != nullptr);
}

// Implements GApplication::shutdown.
static void my_application_shutdown(GApplication* application) {
  // MyApplication* self = MY_APPLICATION(object);

  // Perform any actions required at application shutdown.

  G_APPLICATION_CLASS(my_application_parent_class)->shutdown(application);
}

// Implements GObject::dispose.
static void my_application_dispose(GObject* object) {
  MyApplication* self = MY_APPLICATION(object);
  delete self->desktop;
  self->desktop = nullptr;
  if (self->lease >= 0) {
    close(self->lease);
    self->lease = -1;
  }
  G_OBJECT_CLASS(my_application_parent_class)->dispose(object);
}

static void my_application_class_init(MyApplicationClass* klass) {
  G_APPLICATION_CLASS(klass)->activate = my_application_activate;
  G_APPLICATION_CLASS(klass)->command_line = my_application_command_line;
  G_APPLICATION_CLASS(klass)->startup = my_application_startup;
  G_APPLICATION_CLASS(klass)->shutdown = my_application_shutdown;
  G_OBJECT_CLASS(klass)->dispose = my_application_dispose;
}

static void my_application_init(MyApplication* self) { self->lease = -1; }

MyApplication* my_application_new() {
  // Set the program name to the application ID, which helps various systems
  // like GTK and desktop environments map this running application to its
  // corresponding .desktop file. This ensures better integration by allowing
  // the application to be recognized beyond its binary name.
  g_set_prgname(APPLICATION_ID);

  return MY_APPLICATION(
      g_object_new(my_application_get_type(), "application-id", APPLICATION_ID,
                   "flags", G_APPLICATION_HANDLES_COMMAND_LINE, nullptr));
}
