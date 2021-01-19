#include "util/test_file_util.hpp"

#include <filesystem>

#include <absl/strings/str_cat.h>

#include "util/proto_util.hpp"

namespace test {

namespace {
constexpr char kBaseTestFilesPath[] = ".test_runfiles/";
}

TestFiles::TestFiles() { std::filesystem::remove_all(kBaseTestFilesPath); }
TestFiles::~TestFiles() { std::filesystem::remove_all(kBaseTestFilesPath); }

absl::Status TestFiles::SaveProtoTestFile(
    const google::protobuf::Message& message, const std::string& filename) {
  if (!std::filesystem::exists(kBaseTestFilesPath)) {
    if (!std::filesystem::create_directory(kBaseTestFilesPath)) {
      return absl::PermissionDeniedError(
          absl::StrCat("Failed to create path '", kBaseTestFilesPath, "'."));
    }
  }

  const std::string full_path = absl::StrCat(kBaseTestFilesPath, filename);
  espy::util::SaveProto(message, full_path, /*debug=*/false);
  return absl::OkStatus();
}

std::string TestFiles::GetFullPath(const std::string& filename) const {
  return absl::StrCat(kBaseTestFilesPath, filename);
}

}  // namespace test
