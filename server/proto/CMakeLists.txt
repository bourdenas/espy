project(proto)

protobuf_generate_cpp(GAME_ENTRY_PROTO_SRC GAME_ENTRY_HEADER
  "game_entry.proto"
)
add_library(game_entry_proto
  ${GAME_ENTRY_HEADER} ${GAME_ENTRY_PROTO_SRC}
)
target_link_libraries(game_entry_proto
  ${PROTOBUF_LIBRARY}
)
