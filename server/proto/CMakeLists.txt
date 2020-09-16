project(proto)

set(PROTOS
  "game_entry.proto"
)

protobuf_generate_cpp(PROTO_SRC PROTO_HEADER ${PROTOS})

add_library(espy_proto ${PROTO_HEADER} ${PROTO_SRC})

target_link_libraries(espy_proto
  ${PROTOBUF_LIBRARY}
)
