project(proto)

protobuf_generate_cpp(IGDB_API_PROTO_SRC IGDB_API_HEADER
  "igdbapi.proto"
)
add_library(igdb_api_proto
  ${IGDB_API_HEADER} ${IGDB_API_PROTO_SRC}
)
target_link_libraries(igdb_api_proto
  ${PROTOBUF_LIBRARY}
)

protobuf_generate_cpp(LIBRARY_PROTO_SRC LIBRARY_HEADER
  "library.proto"
)
add_library(library_proto
  ${LIBRARY_HEADER} ${LIBRARY_PROTO_SRC}
)
target_link_libraries(library_proto
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

protobuf_generate_cpp(STEAM_ENTRY_PROTO_SRC STEAM_ENTRY_HEADER
  "steam_entry.proto"
)
add_library(steam_entry_proto
  ${STEAM_ENTRY_HEADER} ${STEAM_ENTRY_PROTO_SRC}
)
target_link_libraries(steam_entry_proto
  ${PROTOBUF_LIBRARY}
)
