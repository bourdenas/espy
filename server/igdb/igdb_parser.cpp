#include "igdb/igdb_parser.hpp"

#include <absl/strings/str_cat.h>
#include <glog/logging.h>
#include <nlohmann/json.hpp>

namespace espy {

using json = nlohmann::json;

absl::StatusOr<std::string> IgdbParser::ParseOAuthResponse(
    std::string_view json_response) const {
  auto json_obj = json::parse(json_response, nullptr, false);
  if (json_obj.is_discarded()) {
    return absl::InvalidArgumentError(
        absl::StrCat("Failed to parse JSON response from Twitch.OAuth2\n",
                     std::string(json_response)));
  }

  auto it = json_obj.find("access_token");
  if (it == json_obj.end() || !it->is_string()) {
    return absl::InvalidArgumentError(absl::StrCat(
        "Response is missing 'access_token' field or has an unexpected type.\n",
        std::string(json_response)));
  }
  return it->get<std::string>();
}

absl::StatusOr<igdb::SearchResultList> IgdbParser::ParseSearchByTitleResponse(
    std::string_view json_response) const {
  igdb::SearchResultList search_result_list;

  auto json_obj = json::parse(json_response, nullptr, false);
  if (json_obj.is_discarded()) {
    return absl::InvalidArgumentError(
        absl::StrCat("Failed to parse JSON response from IGDB.SearchByTitle\n",
                     std::string(json_response)));
  }

  for (const auto& game : json_obj) {
    auto* result = search_result_list.add_result();

    auto it = game.find("id");
    if (it == game.end() || !it->is_number_integer()) {
      return absl::InvalidArgumentError(absl::StrCat(
          "Game in response has no 'id' field or has unexpected type.\n",
          std::string(json_response)));
    }
    result->set_id(it->get<int>());

    it = game.find("name");
    if (it == game.end() || !it->is_string()) {
      return absl::InvalidArgumentError(absl::StrCat(
          "Game in response has no 'title' field or has unexpected type.\n",
          std::string(json_response)));
    }
    result->set_title(*it);
  }

  return search_result_list;
}

}  // namespace espy
