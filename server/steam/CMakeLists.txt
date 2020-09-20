project(steam)

add_library(steam_service
  "steam_service.hpp"
  "steam_service.cpp"
)
target_link_libraries(steam_service PRIVATE
  game_entry_proto
  steam_parser
  
  absl::strings
  glog::glog
  protobuf::libprotobuf-lite
  unofficial::curlpp::curlpp
)

add_library(steam_parser
  "steam_parser.hpp"
  "steam_parser.cpp"
)
target_link_libraries(steam_parser PRIVATE
  game_entry_proto
  
  absl::strings
  glog::glog
  nlohmann_json::nlohmann_json
  protobuf::libprotobuf-lite
)

add_executable(steam_parser_test "steam_parser_test.cpp")
target_link_libraries(steam_parser_test PRIVATE
  steam_parser
  Catch2::Catch2
)
catch_discover_tests(steam_parser_test)
