#ifndef ESPY_SERVER_STEAM_STEAM_PARSER_HPP_
#define ESPY_SERVER_STEAM_STEAM_PARSER_HPP_

#include <string_view>

#include <absl/status/statusor.h>

#include "proto/steam_entry.pb.h"

namespace espy {

class SteamParser {
 public:
  absl::StatusOr<SteamList> ParseGetOwnedGames(
      std::string_view json_response) const;
};

}  // namespace espy

#endif  // ESPY_SERVER_STEAM_STEAM_PARSER_HPP_