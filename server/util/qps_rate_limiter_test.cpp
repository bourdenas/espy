#include "util/qps_rate_limiter.hpp"

#define CATCH_CONFIG_MAIN
#include <catch.hpp>

#include <algorithm>
#include <execution>

namespace espy {

// TestCase is assuming that a simple for-loop of up to 4 counts with
// mutex-locking can be executed in less than a second. This should be easily
// true in any modern machine, but if it is not, this test can be *flaky*.
TEST_CASE("[QpsRateLimiter] Rate limiter based on fixed QPS.",
          "[QpsRateLimiter]") {
  QpsRateLimiter qps_rate(4);

  SECTION("Serial processing") {
    SECTION("Burst below QPS") {
      const auto start = std::chrono::system_clock::now();
      for (int i = 0; i < 2; ++i) {
        const auto wait_time = qps_rate.Wait();
        REQUIRE(wait_time == std::chrono::microseconds(0));
      }
      REQUIRE(std::chrono::system_clock::now() - start <
              std::chrono::seconds(1));
    }

    SECTION("Burst above QPS") {
      const auto start = std::chrono::system_clock::now();
      for (int i = 0; i < 4; ++i) {
        const auto wait_time = qps_rate.Wait();
        REQUIRE(wait_time == std::chrono::microseconds(0));
      }
      REQUIRE(std::chrono::system_clock::now() - start <
              std::chrono::seconds(1));

      const auto wait_time = qps_rate.Wait();
      REQUIRE(wait_time > std::chrono::microseconds(0));
      REQUIRE(std::chrono::system_clock::now() - start >=
              std::chrono::seconds(1));
    }

    SECTION("Rate limit bursts across several seconds") {
      const auto start = std::chrono::system_clock::now();
      for (int i = 0; i < 9; ++i) {
        qps_rate.Wait();
      }
      REQUIRE(std::chrono::system_clock::now() - start >=
              std::chrono::seconds(2));
    }
  }

  SECTION("Parallel processing") {
    SECTION("Burst below QPS") {
      const auto start = std::chrono::system_clock::now();
      std::vector<int> vec = {1, 2, 3};
      std::transform(std::execution::par, vec.begin(), vec.end(), vec.begin(),
                     [&vec, &qps_rate](int e) {
                       qps_rate.Wait();
                       return e * 2;
                     });
      REQUIRE(std::chrono::system_clock::now() - start <
              std::chrono::seconds(1));

      REQUIRE(vec == std::vector<int>{2, 4, 6});
    }

    SECTION("Burst above QPS") {
      const auto start = std::chrono::system_clock::now();
      std::vector<int> vec = {1, 2, 3, 4, 5, 6};
      std::transform(std::execution::par, vec.begin(), vec.end(), vec.begin(),
                     [&vec, &qps_rate](int e) {
                       qps_rate.Wait();
                       return e * 2;
                     });
      REQUIRE(std::chrono::system_clock::now() - start >=
              std::chrono::seconds(1));

      REQUIRE(vec == std::vector<int>{2, 4, 6, 8, 10, 12});
    }
  }
}

}  // namespace espy
