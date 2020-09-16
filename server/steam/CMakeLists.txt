project(steam)

set(SOURCES
  "steam_parser.cpp"
  "steam_service.cpp"
)

add_library(steam ${SOURCES})

target_link_libraries(steam PRIVATE
  espy_proto
  
  absl::strings
  glog::glog
  protobuf::libprotobuf-lite
  unofficial::curlpp::curlpp
)

add_executable(steam_parser_test "steam_parser_test.cpp")
target_link_libraries(steam_parser_test PRIVATE
  steam
  Catch2::Catch2
)
catch_discover_tests(steam_parser_test)
