#ifndef ESPY_SERVICE_ESPY_SERVICE_HPP_
#define ESPY_SERVICE_ESPY_SERVICE_HPP_

#include <grpc/grpc.h>

#include "proto/espy.grpc.pb.h"

namespace espy {

class EspyService final : public Espy::Service {
 public:
  grpc::Status GetLibrary(grpc::ServerContext *context,
                          const LibraryRequest *request,
                          LibraryResponse *response) override;
};

}  // namespace espy

#endif  // ESPY_SERVICE_ESPY_SERVICE_HPP_
