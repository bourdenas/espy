project(util)

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
