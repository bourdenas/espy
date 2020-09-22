project(igdb)

add_library(igdb_service 
  "igdb_service.hpp"
  "igdb_service.cpp"
)
target_link_libraries(igdb_service PRIVATE
  igdb_parser
  search_result_proto

  absl::strings
  glog::glog
  protobuf::libprotobuf-lite
  unofficial::curlpp::curlpp
)

add_library(igdb_parser
  "igdb_parser.hpp"
  "igdb_parser.cpp"
)
target_link_libraries(igdb_parser PRIVATE
  search_result_proto
  
  absl::status
  absl::strings
  glog::glog
  nlohmann_json::nlohmann_json
  protobuf::libprotobuf-lite
)

add_executable(igdb_parser_test "igdb_parser_test.cpp")
target_link_libraries(igdb_parser_test PRIVATE
  igdb_parser
  Catch2::Catch2
)
catch_discover_tests(igdb_parser_test)
