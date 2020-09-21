#include "steam/steam_service.hpp"

#include <memory>
#include <sstream>

#include <absl/strings/str_cat.h>
#include <curlpp/cURLpp.hpp>
#include <curlpp/Easy.hpp>
#include <curlpp/Options.hpp>
#include <glog/logging.h>

#include "steam/steam_parser.hpp"

namespace espy {

constexpr char kSteamHostname[] = "https://api.steampowered.com";
constexpr char kGetOwnedGamesService[] = "/IPlayerService/GetOwnedGames/v0001/";

absl::StatusOr<GameList> SteamService::GetOwnedGames() const {
  const auto host = kSteamHostname;
  const auto target = absl::StrCat(kGetOwnedGamesService, "?",
                                   "key=", steam_key_, "&steamid=", user_id_,
                                   "&include_appinfo=true", "&format=json");

  const auto url = curlpp::options::Url(absl::StrCat(host, target));
  LOG(INFO) << absl::StrCat(host, target);

  curlpp::Easy handle;
  handle.setOpt(url);

  std::ostringstream response;
  handle.setOpt(std::make_unique<curlpp::options::WriteStream>(&response));
  handle.perform();

  return SteamParser().ParseGetOwnedGames(response.str());
}

}  // namespace espy
