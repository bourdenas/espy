#ifndef ESPY_SERVER_UTIL_QPS_RATE_LIMITER_HPP_
#define ESPY_SERVER_UTIL_QPS_RATE_LIMITER_HPP_

#include <chrono>
#include <mutex>

namespace espy {

// Thread-safe RateLimiter based on fixed amount of queries per second (QPS).
class QpsRateLimiter {
 public:
  QpsRateLimiter(int qps_rate)
      : qps_rate_(qps_rate), available_capacity_(qps_rate) {}

  // Blocks execution thread until it is ok to execute next operation based on
  // QPS limit. Returns the amount of time the thread was blocked. Return value
  // is 0 if the thread did not have to block.
  std::chrono::microseconds Wait();

  // Non-blocking variation of the above. Returns amount of time before
  // attempting to Wait() again. Retuns 0 if execution can proceed immidiately.
  std::chrono::microseconds TryWait();

 private:
  std::chrono::microseconds NextAvailable();

  const int qps_rate_;

  std::mutex mutex_;
  int available_capacity_;
  std::chrono::microseconds next_reset_;
};

}  // namespace espy

#endif  // ESPY_SERVER_UTIL_QPS_RATE_LIMITER_HPP_
