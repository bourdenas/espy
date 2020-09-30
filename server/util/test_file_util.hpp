#ifndef ESPY_SERVER_UTIL_TEST_FILE_UTIL_HPP_
#define ESPY_SERVER_UTIL_TEST_FILE_UTIL_HPP_

#include <memory>
#include <ostream>
#include <sstream>

#include <absl/status/status.h>
#include <google/protobuf/message.h>

namespace test {

// Utility class meant to be used for tests only to manage temporary files used
// in testing.
class TestFiles {
 public:
  TestFiles();
  ~TestFiles();

  // Stores a protobuf message into disk.
  absl::Status SaveProtoTestFile(const google::protobuf::Message& message,
                                 const std::string& filename);

  // Returns full path for a file previously saved through this class.
  std::string GetFullPath(const std::string& filename) const;
};

}  // namespace test

#endif  // ESPY_SERVER_UTIL_TEST_FILE_UTIL_HPP_
