#include "desktop_channel.h"

DesktopChannel::~DesktopChannel() {
  requests_.Stop();
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
}
FlValue* DesktopChannel::State() {
  const auto state = requests_.Read();
  auto* result = fl_value_new_map();
  fl_value_set_string_take(result, "available", fl_value_new_bool(available_));
  fl_value_set_string_take(result, "count", fl_value_new_int(state.count));
  if (state.first) {
    fl_value_set_string_take(result, "id", fl_value_new_int(state.first->id));
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
  if (strcmp(name, "dismiss") == 0) {
    auto* args = fl_method_call_get_args(call);
    if (fl_value_get_type(args) != FL_VALUE_TYPE_INT) {
      fl_method_call_respond_error(call, "invalid", "Invalid request.", nullptr,
                                   nullptr);
      return;
    }
    self->requests_.Dismiss(fl_value_get_int(args));
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
  if (accepted) Changed();
  return accepted;
}
