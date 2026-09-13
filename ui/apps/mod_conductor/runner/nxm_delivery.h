#ifndef MOD_CONDUCTOR_NXM_DELIVERY_H_
#define MOD_CONDUCTOR_NXM_DELIVERY_H_
#include "desktop_requests.h"
#include <condition_variable>
#include <functional>
#include <thread>
namespace desktop {
struct Ingress { std::string endpoint; std::vector<uint8_t> capability; int pid = 0; };
class NxmDelivery {
 public:
  NxmDelivery(Requests& requests, std::function<void()> changed);
  ~NxmDelivery();
  void Configure(Ingress value);
  void Notify();
  void Stop();
 private:
  void Run();
  bool Send(const Ingress& target, const PrivateRequest& request, bool dismiss);
  Requests& requests_;
  std::function<void()> changed_;
  std::mutex mutex_;
  std::condition_variable event_;
  bool stopping_ = false, notified_ = false;
  Ingress target_;
  std::thread worker_;
};
}
#endif
