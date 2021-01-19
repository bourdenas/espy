project(igdb)

add_library(igdb_service 
  "igdb_service.hpp"
  "igdb_service.cpp"
)
target_link_libraries(igdb_service PRIVATE
  igdb_api_proto
  igdb_parser
  library_proto

  absl::statusor
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
  igdb_service
  library_proto
  qps_rate_limiter
  reconciliation_task_proto
  steam_entry_proto

  absl::statusor
  absl::strings
  glog::glog
  TBB::tbb
)



add_executable(reconciliation_service_test "reconciliation_service_test.cpp")
target_link_libraries(reconciliation_service_test PRIVATE
  reconciliation_service
  Catch2::Catch2
)
catch_discover_tests(reconciliation_service_test)
