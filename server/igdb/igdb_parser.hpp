#ifndef ESPY_SERVER_IGDB_IGDB_PARSER_HPP_
#define ESPY_SERVER_IGDB_IGDB_PARSER_HPP_

#include <string_view>

#include <absl/status/statusor.h>

#include "proto/search_result.pb.h"

namespace espy {

class IgdbParser {
 public:
  absl::StatusOr<std::string> ParseOAuthResponse(
      std::string_view json_response) const;

  absl::StatusOr<igdb::SearchResultList> ParseSearchByTitleResponse(
      std::string_view json_response) const;

  absl::StatusOr<std::string> ParseGetCoverResponse(
      std::string_view json_response) const;
};

}  // namespace espy

#endif  // ESPY_SERVER_IGDB_IGDB_PARSER_HPP_
