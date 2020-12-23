project(util)

add_library(qps_rate_limiter 
  "qps_rate_limiter.hpp"
  "qps_rate_limiter.cpp"
)

add_library(proto_util 
  "proto_util.hpp"
  "proto_util.cpp"
)
target_link_libraries(proto_util PRIVATE
  absl::strings
  glog::glog
  protobuf::libprotobuf-lite
)

add_library(test_file_util
  "test_file_util.hpp"
  "test_file_util.cpp"
)
target_link_libraries(test_file_util PRIVATE
  absl::strings
  absl::status
  protobuf::libprotobuf-lite
)


add_executable(qps_rate_limiter_test "qps_rate_limiter_test.cpp")
target_link_libraries(qps_rate_limiter_test PRIVATE
  qps_rate_limiter
  Catch2::Catch2
)
catch_discover_tests(qps_rate_limiter_test)
