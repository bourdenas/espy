#ifndef ESPY_SERVER_IGDB_IGDB_PARSER_HPP_
#define ESPY_SERVER_IGDB_IGDB_PARSER_HPP_

#include <string>
#include <string_view>
#include <vector>

#include <absl/status/statusor.h>

namespace espy {

class IgdbParser {
 public:
  absl::StatusOr<std::string> ParseOAuthResponse(
      std::string_view json_response) const;
};

}  // namespace espy

#endif  // ESPY_SERVER_IGDB_IGDB_PARSER_HPP_
