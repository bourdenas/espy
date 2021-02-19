project(service)

add_library(espy_service
  "espy_service.hpp"
  "espy_service.cpp"
)
target_link_libraries(espy_service PRIVATE
  espy_proto  

  gRPC::grpc++
)
