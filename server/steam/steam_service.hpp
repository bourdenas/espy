#ifndef ESPY_SERVER_STEAM_STEAM_SERVICE_HPP_
#define ESPY_SERVER_STEAM_STEAM_SERVICE_HPP_

#include <string>

#include <absl/status/statusor.h>

#include "proto/game_entry.pb.h"

namespace espy {

class SteamService {
 public:
  SteamService(std::string steam_key, std::string user_id)
      : steam_key_(std::move(steam_key)), user_id_(std::move(user_id)) {}

  absl::StatusOr<GameList> GetOwnedGames() const;

 private:
  std::string steam_key_;
  std::string user_id_;
};

}  // namespace espy

#endif  // ESPY_SERVER_STEAM_STEAM_SERVICE_HPP_
