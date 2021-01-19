project(json)

add_library(igdb_parser
  "igdb_parser.hpp"
  "igdb_parser.cpp"
)
target_link_libraries(igdb_parser PRIVATE
  json_util
  library_proto
    
  absl::statusor
  absl::strings
  glog::glog
  nlohmann_json::nlohmann_json
  protobuf::libprotobuf-lite
)

add_library(json_util
  "json_util.hpp"
  "json_util.cpp"
)
target_link_libraries(json_util PRIVATE
  absl::statusor
  absl::strings
  nlohmann_json::nlohmann_json
)

add_library(key_parser
  "key_parser.hpp"
  "key_parser.cpp"
)
target_link_libraries(key_parser PRIVATE
  json_util

  absl::statusor
  absl::strings
  glog::glog
  nlohmann_json::nlohmann_json
)

add_library(steam_parser
  "steam_parser.hpp"
  "steam_parser.cpp"
)
target_link_libraries(steam_parser PRIVATE
  json_util
  steam_entry_proto
  
  absl::statusor
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

add_executable(steam_parser_test "steam_parser_test.cpp")
target_link_libraries(steam_parser_test PRIVATE
  steam_parser
  Catch2::Catch2
)
catch_discover_tests(steam_parser_test)
