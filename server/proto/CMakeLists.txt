project(proto)

set(_PROTOBUF_PROTOC $<TARGET_FILE:protobuf::protoc>)
set(_GRPC_CPP_PLUGIN_EXECUTABLE $<TARGET_FILE:gRPC::grpc_cpp_plugin>)
get_filename_component(espy_proto_path "espy.proto" PATH)
message(STATUS "path=${espy_proto_path}")

set(ESPY_PROTO_SRC "${CMAKE_CURRENT_BINARY_DIR}/espy.pb.cc")
set(ESPY_PROTO_HDR "${CMAKE_CURRENT_BINARY_DIR}/espy.pb.h")
set(ESPY_GRPC_SRC "${CMAKE_CURRENT_BINARY_DIR}/espy.grpc.pb.cc")
set(ESPY_GRPC_HDR "${CMAKE_CURRENT_BINARY_DIR}/espy.grpc.pb.h")
add_custom_command(
      OUTPUT "${ESPY_PROTO_SRC}" "${ESPY_PROTO_HDR}" "${ESPY_GRPC_SRC}" "${ESPY_GRPC_HDR}"
      COMMAND ${_PROTOBUF_PROTOC}
      ARGS --grpc_out "${CMAKE_CURRENT_BINARY_DIR}"
        --cpp_out "${CMAKE_CURRENT_BINARY_DIR}"
        -I "/home/bourdenas/dev/espy/server/proto/"
        --plugin=protoc-gen-grpc="${_GRPC_CPP_PLUGIN_EXECUTABLE}"
        "espy.proto"
      DEPENDS "espy.proto")

add_library(espy_proto
  ${ESPY_PROTO_HDR} ${ESPY_PROTO_SRC}
  ${ESPY_GRPC_HDR} ${ESPY_GRPC_SRC}
)
target_link_libraries(espy_proto
  ${PROTOBUF_LIBRARY}
  library_proto
)


protobuf_generate_cpp(IGDB_API_PROTO_SRC IGDB_API_PROTO_HDR
  "igdbapi.proto"
)
add_library(igdb_api_proto
  ${IGDB_API_PROTO_HDR} ${IGDB_API_PROTO_SRC}
)
target_link_libraries(igdb_api_proto
  ${PROTOBUF_LIBRARY}
)

protobuf_generate_cpp(LIBRARY_PROTO_SRC LIBRARY_PROTO_HDR
  "library.proto"
)
add_library(library_proto
  ${LIBRARY_PROTO_HDR} ${LIBRARY_PROTO_SRC}
)
target_link_libraries(library_proto
  ${PROTOBUF_LIBRARY}
  igdb_api_proto
  steam_entry_proto
)

protobuf_generate_cpp(RECON_TASK_PROTO_SRC RECON_TASK_PROTO_HDR
  "reconciliation_task.proto"
)
add_library(reconciliation_task_proto
  ${RECON_TASK_PROTO_HDR} ${RECON_TASK_PROTO_SRC}
)
target_link_libraries(reconciliation_task_proto
  ${PROTOBUF_LIBRARY}
  igdb_api_proto
  steam_entry_proto
)

protobuf_generate_cpp(STEAM_ENTRY_PROTO_SRC STEAM_ENTRY_PROTO_HDR
  "steam_entry.proto"
)
add_library(steam_entry_proto
  ${STEAM_ENTRY_PROTO_HDR} ${STEAM_ENTRY_PROTO_SRC}
)
target_link_libraries(steam_entry_proto
  ${PROTOBUF_LIBRARY}
)
