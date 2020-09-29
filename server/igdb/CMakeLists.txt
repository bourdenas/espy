project(igdb)

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

add_library(reconciliation_service 
  "reconciliation_service.hpp"
  "reconciliation_service.cpp"
)
target_link_libraries(reconciliation_service PRIVATE
  game_entry_proto
  igdb_service
  reconciliation_task_proto
  search_result_proto
  steam_entry_proto

  absl::strings
  absl::status
  glog::glog
)

add_executable(igdb_parser_test "igdb_parser_test.cpp")
target_link_libraries(igdb_parser_test PRIVATE
  igdb_parser
  Catch2::Catch2
)
catch_discover_tests(igdb_parser_test)

add_executable(reconciliation_service_test "reconciliation_service_test.cpp")
target_link_libraries(reconciliation_service_test PRIVATE
  reconciliation_service
  Catch2::Catch2
)
catch_discover_tests(reconciliation_service_test)
