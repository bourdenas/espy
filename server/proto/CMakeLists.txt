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

protobuf_generate_cpp(RECONCILIATION_TASK_PROTO_SRC RECONCILIATION_TASK_HEADER
  "reconciliation_task.proto"
)
add_library(reconciliation_task_proto
  ${RECONCILIATION_TASK_HEADER} ${RECONCILIATION_TASK_PROTO_SRC}
)
target_link_libraries(reconciliation_task_proto
  ${PROTOBUF_LIBRARY}
)

protobuf_generate_cpp(SEARCH_RESULT_PROTO_SRC SEARCH_RESULT_HEADER
  "search_result.proto"
)
add_library(search_result_proto
  ${SEARCH_RESULT_HEADER} ${SEARCH_RESULT_PROTO_SRC}
)
target_link_libraries(search_result_proto
  ${PROTOBUF_LIBRARY}
)

protobuf_generate_cpp(STEAM_ENTRY_PROTO_SRC STEAM_ENTRY_HEADER
  "steam_entry.proto"
)
add_library(steam_entry_proto
  ${STEAM_ENTRY_HEADER} ${STEAM_ENTRY_PROTO_SRC}
)
target_link_libraries(steam_entry_proto
  ${PROTOBUF_LIBRARY}
)
