#include "json/steam_parser.hpp"

#include <absl/strings/str_cat.h>
#include <glog/logging.h>
#include <nlohmann/json.hpp>

#include "json/json_util.hpp"

namespace espy {

absl::StatusOr<SteamList> SteamParser::ParseGetOwnedGames(
    std::string_view json_response) const {
  SteamList game_list;

  auto json_obj = nlohmann::json::parse(json_response, nullptr, false);
  if (json_obj.is_discarded()) {
    return absl::InvalidArgumentError(
        "Failed to parse JSON response from Steam.ParseGetOwnedGames.");
  }

  for (const auto& game : json_obj["response"]["games"]) {
    auto* entry = game_list.add_game();

    auto appid = json::GetInt(game, "appid");
    if (!appid.ok()) {
      return appid.status();
    }
    entry->set_id(*appid);

    auto name = json::GetString(game, "name");
    if (!name.ok()) {
      return name.status();
    }
    entry->set_title(*name);
  }

  return game_list;
}

}  // namespace espy
