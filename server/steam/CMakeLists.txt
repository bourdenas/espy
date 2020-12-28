project(steam)

add_library(steam_library
  "steam_library.hpp"
  "steam_library.cpp"
)
target_link_libraries(steam_library PRIVATE
  library_proto
  proto_util
  reconciliation_service
  steam_service  

  absl::status
  absl::strings
  glog::glog
  protobuf::libprotobuf-lite
)

add_library(steam_service
  "steam_service.hpp"
  "steam_service.cpp"
)
target_link_libraries(steam_service PRIVATE
  steam_entry_proto
  steam_parser
  
  absl::strings
  glog::glog
  protobuf::libprotobuf-lite
  unofficial::curlpp::curlpp
)



add_executable(steam_library_test "steam_library_test.cpp")
target_link_libraries(steam_library_test PRIVATE
  steam_library
  test_file_util
  Catch2::Catch2
)
catch_discover_tests(steam_library_test)
