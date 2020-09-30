#include <fstream>

#include <absl/status/statusor.h>
#include <absl/strings/str_cat.h>
#include <glog/logging.h>
#include <google/protobuf/message.h>

namespace espy {
namespace util {

// Load a proto message from text file.
template <class Message>
absl::StatusOr<Message> LoadProto(const std::string& path) {
  DLOG(INFO) << "Loading proto text file '" << path << "'...";
  std::fstream istream(path, std::ios::in | std::ios::binary);

  Message message;
  if (!message.ParseFromIstream(&istream)) {
    return absl::FailedPreconditionError(
        absl::StrCat("Failed to parse message in file: ", path));
  }
  return message;
}

// Saves a protobuf message on disk. Produces a binary files and a
// human-readable text file for debug purposes. If |filename_base| empty this
// function is a noop.
void SaveProto(const google::protobuf::Message& message,
               const std::string& filename_base, bool debug = true);

}  // namespace util
}  // namespace espy
