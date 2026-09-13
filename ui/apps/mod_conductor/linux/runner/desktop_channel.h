#ifndef MOD_CONDUCTOR_DESKTOP_CHANNEL_H_
#define MOD_CONDUCTOR_DESKTOP_CHANNEL_H_
#include <flutter_linux/flutter_linux.h>

#include "../../runner/desktop_requests.h"

class DesktopChannel {
 public:
  explicit DesktopChannel(bool available) : available_(available) {}
  ~DesktopChannel();
  void Attach(FlBinaryMessenger* messenger);
  bool Add(const desktop::Arguments& arguments);

 private:
  static void Call(FlMethodChannel*, FlMethodCall*, gpointer);
  FlValue* State();
  void Changed();
  bool available_;
  desktop::Requests requests_;
  FlMethodChannel* channel_ = nullptr;
};
#endif
