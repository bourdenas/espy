#include "steam/steam_parser.hpp"

#include <absl/strings/str_cat.h>
#include <glog/logging.h>
#include <nlohmann/json.hpp>

namespace espy {

using json = nlohmann::json;

GameList SteamParser::ParseGetOwnedGames(std::string_view json_response) const {
  GameList game_list;

  auto json_obj = json::parse(json_response, nullptr, false);
  if (json_obj.is_discarded()) {
    return game_list;
  }

  for (const auto& game : json_obj["response"]["games"]) {
    auto* entry = game_list.add_game();

    auto it = game.find("name");
    if (it == game.end() || !it->is_string()) continue;
    entry->set_title(*it);

    it = game.find("appid");
    if (it == game.end() || !it->is_number_integer()) continue;
    entry->set_steam_id(it->get<int>());
  }

  return game_list;
}

}  // namespace espy
