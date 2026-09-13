#include "desktop_channel.h"
#include <unistd.h>

DesktopChannel::~DesktopChannel() {
  alive_->store(false);
  requests_.Stop();
  nxm_.reset();
  if (channel_) {
    fl_method_channel_set_method_call_handler(channel_, nullptr, nullptr,
                                              nullptr);
    g_object_unref(channel_);
  }
}
void DesktopChannel::Attach(FlBinaryMessenger* messenger) {
  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  channel_ = fl_method_channel_new(messenger, "dev.modconductor/desktop",
                                   FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(channel_, Call, this, nullptr);
  const auto alive = alive_;
  nxm_ = std::make_unique<desktop::NxmDelivery>(requests_, [this, alive] {
    auto* callback = new std::function<void()>([this, alive] { if (alive->load()) Changed(); });
    g_idle_add_full(G_PRIORITY_DEFAULT, [](gpointer data) -> gboolean {
      (*static_cast<std::function<void()>*>(data))(); return G_SOURCE_REMOVE;
    }, callback, [](gpointer data) { delete static_cast<std::function<void()>*>(data); });
  });
}
FlValue* DesktopChannel::State() {
  const auto state = requests_.Read();
  auto* result = fl_value_new_map();
  fl_value_set_string_take(result, "available", fl_value_new_bool(available_));
  fl_value_set_string_take(result, "count", fl_value_new_int(state.count));
  fl_value_set_string_take(result, "processId", fl_value_new_int(getpid()));
  if (state.first) {
    fl_value_set_string_take(result, "id", fl_value_new_int(state.first->id));
    fl_value_set_string_take(result, "nxmPending", fl_value_new_bool(state.first->private_pending));
    fl_value_set_string_take(result, "nxmFailed", fl_value_new_bool(state.first->delivery_failed));
    fl_value_set_string_take(result, "nxmReference", fl_value_new_string(state.first->reference.c_str()));
    auto* args = fl_value_new_list();
    for (const auto& arg : state.first->arguments)
      fl_value_append_take(args, fl_value_new_string(arg.c_str()));
    fl_value_set_string_take(result, "arguments", args);
  }
  return result;
}
void DesktopChannel::Call(FlMethodChannel*, FlMethodCall* call, gpointer data) {
  auto* self = static_cast<DesktopChannel*>(data);
  const auto* name = fl_method_call_get_name(call);
  if (strcmp(name, "configureNxm") == 0) {
    auto* args = fl_method_call_get_args(call);
    if (fl_value_get_type(args) != FL_VALUE_TYPE_MAP) {
      fl_method_call_respond_error(call, "invalid", "Invalid desktop connection.", nullptr, nullptr); return;
    }
    auto* endpoint = fl_value_lookup_string(args, "endpoint");
    auto* capability = fl_value_lookup_string(args, "capability");
    auto* pid = fl_value_lookup_string(args, "processId");
    if (!endpoint || !capability || !pid || fl_value_get_type(endpoint) != FL_VALUE_TYPE_STRING || fl_value_get_type(capability) != FL_VALUE_TYPE_UINT8_LIST || fl_value_get_length(capability) != 32 || fl_value_get_type(pid) != FL_VALUE_TYPE_INT) {
      fl_method_call_respond_error(call, "invalid", "Invalid desktop connection.", nullptr, nullptr); return;
    }
    const auto* bytes = fl_value_get_uint8_list(capability);
    self->nxm_->Configure({fl_value_get_string(endpoint), {bytes, bytes+32}, static_cast<int>(fl_value_get_int(pid))});
  } else if (strcmp(name, "dismiss") == 0) {
    auto* args = fl_method_call_get_args(call);
    if (fl_value_get_type(args) != FL_VALUE_TYPE_INT) {
      fl_method_call_respond_error(call, "invalid", "Invalid request.", nullptr,
                                   nullptr);
      return;
    }
    self->requests_.Dismiss(fl_value_get_int(args));
    self->nxm_->Notify();
  } else if (strcmp(name, "state") != 0) {
    fl_method_call_respond_not_implemented(call, nullptr);
    return;
  }
  g_autoptr(FlValue) result = self->State();
  fl_method_call_respond_success(call, result, nullptr);
}
void DesktopChannel::Changed() {
  if (channel_)
    fl_method_channel_invoke_method(channel_, "changed", nullptr, nullptr,
                                    nullptr, nullptr);
}
bool DesktopChannel::Add(const desktop::Arguments& args) {
  const bool accepted = requests_.Add(args);
  if (accepted) { if (nxm_) nxm_->Notify(); Changed(); }
  return accepted;
}
