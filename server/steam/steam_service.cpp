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

GameList SteamService::GetOwnedGames() const {
  const auto host = kSteamHostname;
  const auto target = absl::StrCat(kGetOwnedGamesService, "?",
                                   "key=", steam_key_, "&steamid=", user_id_,
                                   "&include_appinfo=true", "&format=json");

  curlpp::Cleanup cleaner;
  curlpp::Easy request;

  const auto url = curlpp::options::Url(absl::StrCat(host, target));
  LOG(INFO) << absl::StrCat(host, target);
  request.setOpt(url);

  std::ostringstream response;
  request.setOpt(std::make_unique<curlpp::options::WriteStream>(&response));
  request.perform();

  return SteamParser().ParseGetOwnedGames(response.str());
}

}  // namespace espy
