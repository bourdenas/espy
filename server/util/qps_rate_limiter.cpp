#include "util/qps_rate_limiter.hpp"

#include <thread>

namespace espy {

std::chrono::microseconds QpsRateLimiter::Wait() {
  std::chrono::microseconds total_wait_time(0);

  while (1) {
    const auto wait_time = NextAvailable();
    if (wait_time == std::chrono::microseconds(0)) {
      break;
    }

    total_wait_time += wait_time;
    std::this_thread::sleep_for(wait_time);
  }

  return total_wait_time;
}

std::chrono::microseconds QpsRateLimiter::TryWait() { return NextAvailable(); }

std::chrono::microseconds QpsRateLimiter::NextAvailable() {
  std::lock_guard<std::mutex> lock(mutex_);

  std::chrono::microseconds now =
      std::chrono::duration_cast<std::chrono::microseconds>(
          std::chrono::system_clock::now().time_since_epoch());

  if (next_reset_ < now) {
    available_capacity_ = qps_rate_;
    next_reset_ = now + std::chrono::seconds(1);
  }

  if (available_capacity_ > 0) {
    --available_capacity_;
    return std::chrono::microseconds(0);
  }

  return next_reset_ - now;
}

}  // namespace espy
