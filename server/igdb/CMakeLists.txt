project(igdb)

add_library(igdb_service 
  "igdb_service.hpp"
  "igdb_service.cpp"
)

target_link_libraries(igdb_service PRIVATE
  absl::strings
  glog::glog
  protobuf::libprotobuf-lite
  unofficial::curlpp::curlpp
)
