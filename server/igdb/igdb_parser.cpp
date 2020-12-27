#include "igdb/igdb_parser.hpp"

#include <absl/strings/str_cat.h>
#include <nlohmann/json.hpp>

namespace espy {

using json = nlohmann::json;

namespace {
absl::StatusOr<int> GetInt(const json& obj, std::string_view field_name) {
  const auto it = obj.find(field_name);
  if (it == obj.end() || !it->is_number_integer()) {
    return absl::NotFoundError(
        absl::StrCat("Response has no '", std::string(field_name),
                     "' field or its type is not Integer."));
  }
  return it->get<int>();
}

absl::StatusOr<std::string> GetString(const json& obj,
                                      std::string_view field_name) {
  const auto it = obj.find(field_name);
  if (it == obj.end() || !it->is_string()) {
    return absl::NotFoundError(
        absl::StrCat("Response has no '", std::string(field_name),
                     "' field or its type is not String."));
  }
  return it->get<std::string>();
}
}  // namespace

absl::StatusOr<std::string> IgdbParser::ParseOAuthResponse(
    std::string_view json_response) const {
  auto json_obj = json::parse(json_response, nullptr, false);
  if (json_obj.is_discarded()) {
    return absl::InvalidArgumentError(
        absl::StrCat("Failed to parse JSON response from Twitch.OAuth2\n",
                     std::string(json_response)));
  }

  return GetString(json_obj, "access_token");
}

}  // namespace espy
