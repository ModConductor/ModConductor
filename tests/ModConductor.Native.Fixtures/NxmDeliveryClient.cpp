#include "../../ui/apps/mod_conductor/runner/nxm_delivery.h"
#include <sys/socket.h>
#include <sys/un.h>
#include <unistd.h>
#include <atomic>
#include <chrono>
#include <cstring>
#include <iostream>
#include <stdexcept>
#include <thread>
using namespace std::chrono_literals;

void check(bool value, const char* detail) {
  if (!value) throw std::runtime_error(detail);
}
void check_queue_order() {
  desktop::Requests queued;
  const desktop::Arguments olderA{"--workspace", "/older-a"};
  const desktop::Arguments olderB{"--workspace", "/older-b"};
  const desktop::Arguments linkA{"--uri", "nxm://skyrimspecialedition/mods/1/files/1?key=a"};
  const desktop::Arguments linkB{"--uri", "nxm://skyrimspecialedition/mods/1/files/2?key=b"};
  check(queued.Add(olderA) && queued.Add(olderB) && queued.Add(linkA), "Queue setup failed.");
  const auto firstLink = queued.Read().first.value();
  check(firstLink.reference.size() == 32 && queued.Read().count == 3, "Incoming NXM did not lead older requests.");
  check(queued.Add(linkB), "Second NXM was refused.");
  const auto secondLink = queued.Read().first.value();
  check(secondLink.id != firstLink.id && queued.Read().count == 4, "Newest NXM did not lead the queue.");
  check(queued.Add(linkA) && queued.Read().first->id == firstLink.id && queued.Read().count == 4,
        "Repeated NXM did not expose its existing request.");
  check(queued.Add(linkB) && queued.Read().first->id == secondLink.id && queued.Read().count == 4,
        "Repeated NXM created a duplicate or lost newest priority.");
  queued.Dismiss(secondLink.id);
  check(queued.Read().first->id == firstLink.id, "Earlier NXM was discarded.");
  queued.Dismiss(firstLink.id);
  check(queued.Read().first->arguments == olderA && queued.Read().count == 2, "First older request was discarded or reordered.");
  queued.Dismiss(queued.Read().first->id);
  check(queued.Read().first->arguments == olderB, "Second older request was discarded or reordered.");

  desktop::Requests preempted;
  check(preempted.Add(olderA), "Older request admission failed.");
  const auto oldId = preempted.Read().first->id;
  check(preempted.Add(linkA), "Preempting NXM was refused.");
  const auto newId = preempted.Read().first->id;
  preempted.Dismiss(oldId);
  check(preempted.Read().count == 1 && preempted.Read().first->id == newId,
        "Dismissing preempted work removed the incoming NXM or retained old work.");
}
template<class Predicate> void until(Predicate ready) {
  const auto end = std::chrono::steady_clock::now() + 10s;
  while (!ready() && std::chrono::steady_clock::now() < end) std::this_thread::sleep_for(5ms);
  check(ready(), "Native delivery did not reach the expected state.");
}
std::string owner(const std::string& command) {
  std::cout << command << std::endl;
  std::string answer;
  check(bool(std::getline(std::cin, answer)), "Owner control channel closed.");
  return answer;
}
void exact(int fd, uint8_t* bytes, size_t size, bool write) {
  for (size_t offset = 0; offset < size;) {
    const auto count = write ? send(fd, bytes + offset, size - offset, MSG_NOSIGNAL)
                             : recv(fd, bytes + offset, size - offset, 0);
    check(count > 0, "Private fixture frame was incomplete.");
    offset += static_cast<size_t>(count);
  }
}
int connection(const std::string& path) {
  int fd = socket(AF_UNIX, SOCK_STREAM | SOCK_CLOEXEC, 0);
  check(fd >= 0, "Fixture socket creation failed.");
  timeval timeout{5, 0};
  setsockopt(fd, SOL_SOCKET, SO_RCVTIMEO, &timeout, sizeof(timeout));
  setsockopt(fd, SOL_SOCKET, SO_SNDTIMEO, &timeout, sizeof(timeout));
  sockaddr_un address{}; address.sun_family = AF_UNIX;
  check(path.size() < sizeof(address.sun_path), "Fixture socket path is too long.");
  std::memcpy(address.sun_path, path.c_str(), path.size() + 1);
  check(connect(fd, reinterpret_cast<sockaddr*>(&address), sizeof(address)) == 0, "Fixture engine connection failed.");
  return fd;
}
class Relay {
 public:
  Relay(std::string endpoint, std::string engine) : endpoint_(std::move(endpoint)), engine_(std::move(engine)) {
    listener_ = socket(AF_UNIX, SOCK_STREAM | SOCK_CLOEXEC, 0);
    check(listener_ >= 0, "Fixture listener creation failed.");
    sockaddr_un address{}; address.sun_family = AF_UNIX;
    check(endpoint_.size() < sizeof(address.sun_path), "Fixture relay path is too long.");
    std::memcpy(address.sun_path, endpoint_.c_str(), endpoint_.size() + 1);
    check(bind(listener_, reinterpret_cast<sockaddr*>(&address), sizeof(address)) == 0 && listen(listener_, 2) == 0, "Fixture relay bind failed.");
    worker_ = std::thread([this] { run(); });
  }
  ~Relay() {
    stopping = true; hold = false;
    shutdown(listener_, SHUT_RDWR);
    if (worker_.joinable()) worker_.join();
    close(listener_); unlink(endpoint_.c_str());
  }
  std::atomic<bool> drop{true}, hold{false}, waiting{false}, failed{false}, stopping{false};
  std::atomic<int> dismissals{0};
 private:
  void run() {
    while (!stopping) {
      int client = accept4(listener_, nullptr, nullptr, SOCK_CLOEXEC);
      if (client < 0) break;
      int engine = -1;
      try {
        timeval timeout{5, 0};
        setsockopt(client, SOL_SOCKET, SO_RCVTIMEO, &timeout, sizeof(timeout));
        std::vector<uint8_t> frame(53);
        exact(client, frame.data(), frame.size(), false);
        const bool dismiss = frame[0] == 2;
        uint32_t size = 0;
        for (int i = 0; i < 4; ++i) size |= uint32_t(frame[49 + i]) << (8 * i);
        check(size <= 4096, "Fixture frame exceeded the bound.");
        frame.resize(53 + size);
        if (size) exact(client, frame.data() + 53, size, false);
        waiting = true;
        until([this] { return !hold || stopping; });
        waiting = false;
        engine = connection(engine_);
        exact(engine, frame.data(), frame.size(), true);
        uint8_t reply[16]{};
        exact(engine, reply, sizeof(reply), false);
        check(std::memcmp(reply, frame.data() + 33, 16) == 0, "Engine refused the fixture frame.");
        // Admission has completed. Losing only this reply creates C1 without changing the engine.
        if (dismiss || !drop.exchange(false)) exact(client, reply, sizeof(reply), true);
        if (dismiss) ++dismissals;
        std::fill(frame.begin(), frame.end(), 0);
      } catch (...) { failed = true; }
      if (engine >= 0) close(engine);
      close(client);
    }
  }
  std::string endpoint_, engine_;
  int listener_ = -1;
  std::thread worker_;
};
int main(int argc, char** argv) {
  try {
    if (argc == 2 && std::string(argv[1]) == "--queue") {
      check_queue_order();
      return 0;
    }
    check(argc == 2, "Expected a private fixture directory.");
    check_queue_order();
    std::string endpoint, capability, pid;
    check(bool(std::getline(std::cin, endpoint)) && bool(std::getline(std::cin, capability)) && bool(std::getline(std::cin, pid)), "Missing private fixture descriptor.");
    std::vector<uint8_t> bytes;
    for (size_t i = 0; i < capability.size(); i += 2) bytes.push_back(static_cast<uint8_t>(std::stoul(capability.substr(i, 2), nullptr, 16)));
    Relay relay(std::string(argv[1]) + "/relay", endpoint);
    desktop::Requests requests;
    desktop::NxmDelivery delivery(requests, [] {});
    const desktop::Ingress target{std::string(argv[1]) + "/relay", bytes, getpid()};
    auto add = [&](int file) {
      check(requests.Add({"--uri", "nxm://skyrimspecialedition/mods/1/files/" + std::to_string(file) + "?key=synthetic-lost-ack&expires=4102444800&user_id=42"}), "Native request admission failed.");
      return requests.Read().first.value();
    };
    auto failed = [&] { auto state = requests.Read(); return state.first && state.first->delivery_failed; };
    auto dismiss = [&](const desktop::Request& request) {
      // This is the existing Dart ordering: dismiss the opaque owner reference, then the native slot.
      if (!request.reference.empty()) check(owner("dismiss " + request.reference) == "ok", "Owner dismissal failed.");
      requests.Dismiss(request.id); delivery.Notify();
    };
    auto first = add(1);
    const auto firstReference = desktop::Reference(requests.Pending()->id);
    delivery.Configure(target);
    until(failed);
    check(requests.Read().first->private_pending, "Lost reply became an acknowledged admission.");
    check(owner("present " + firstReference) == "yes", "Engine had not admitted the lost-reply request.");
    dismiss(first);
    check(owner("present " + firstReference) == "no" && owner("capacity") == "16", "Failed-delivery dismissal retained engine authorization/capacity.");
    check(owner("passed admittedLostReplyDismissReleasesCapacity") == "ok", "Observation failed.");

    relay.drop = true;
    auto retry = add(2); delivery.Notify(); until(failed);
    delivery.Configure(target);
    until([&] { return requests.Read().first && !requests.Read().first->private_pending; });
    check(requests.Read().first->reference == retry.reference && owner("present " + retry.reference) == "yes", "Retry changed the opaque submission identity.");
    dismiss(retry);
    check(owner("capacity") == "16", "Same-ID retry duplicated engine authorization.");
    check(owner("passed lostReplyRetryKeepsSubmissionIdentity") == "ok", "Observation failed.");

    relay.drop = true; relay.hold = true;
    auto inflight = add(3); delivery.Notify();
    until([&] { return relay.waiting.load(); });
    check(owner("present " + inflight.reference) == "no", "Fixture did not stop before admission.");
    dismiss(inflight);
    relay.hold = false;
    until([&] { return relay.dismissals == 1 || relay.failed; });
    check(!relay.failed && owner("present " + inflight.reference) == "no" && owner("capacity") == "16", "In-flight dismissal plus lost reply retained authorization.");
    check(owner("passed inFlightDismissUsesPrivateCleanupAfterLostReply") == "ok", "Observation failed.");
    delivery.Stop();
    check(requests.Read().count == 0 && !relay.failed, "Fixture did not drain its request queue.");
    return 0;
  } catch (const std::exception& error) { std::cerr << error.what(); return 1; }
}
