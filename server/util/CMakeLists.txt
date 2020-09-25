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
