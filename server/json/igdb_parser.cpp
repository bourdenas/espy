#include "json/igdb_parser.hpp"

#include <absl/strings/str_cat.h>
#include <nlohmann/json.hpp>

#include "json/json_util.hpp"

namespace espy {

absl::StatusOr<std::string> IgdbParser::ParseOAuthResponse(
    std::string_view json_response) const {
  auto json_obj = nlohmann::json::parse(json_response, nullptr, false);
  if (json_obj.is_discarded()) {
    return absl::InvalidArgumentError(
        absl::StrCat("Failed to parse JSON response from Twitch.OAuth2\n",
                     std::string(json_response)));
  }

  return json::GetString(json_obj, "access_token");
}

}  // namespace espy
