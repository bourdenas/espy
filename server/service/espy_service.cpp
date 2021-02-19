#include "service/espy_service.hpp"

namespace espy {

grpc::Status EspyService::GetLibrary(grpc::ServerContext* context,
                                     const LibraryRequest* request,
                                     LibraryResponse* response) {
  return grpc::Status::OK;
}

}  // namespace espy
