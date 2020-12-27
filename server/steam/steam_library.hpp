#ifndef ESPY_SERVER_STEAM_STEAM_LIBRARY_HPP_
#define ESPY_SERVER_STEAM_STEAM_LIBRARY_HPP_

#include <string>

#include <absl/status/status.h>

#include "proto/library.pb.h"
#include "steam/steam_service.hpp"
#include "igdb/reconciliation_service.hpp"

namespace espy {

// Manages a Steam library maintaining local copy of games and syncing with
// source. It also reconciles Steam game entries with IGDB listings.
class SteamLibrary {
 public:
  static absl::StatusOr<SteamLibrary> Create(
      std::string espy_user_id, const SteamService* steam_service,
      const ReconciliationService* reconciliation_service);

  // Fetches Steam listing using the Web API and updates local copy with
  // additions.
  // NOTE: Does't bother to check for removed entries.
  // NOTE: Ignores Steam entries that fails to retrieve IGDB listings for now.
  absl::Status Sync();

  const Library& games() const { return library_; }

 private:
  SteamLibrary(std::string espy_user_id, const SteamService* steam_service,
               const ReconciliationService* reconciliation_service)
      : espy_user_id_(std::move(espy_user_id)),
        steam_service_(steam_service),
        reconciler_(reconciliation_service) {}

  std::string espy_user_id_;
  const SteamService* steam_service_;
  const ReconciliationService* reconciler_;

  Library library_;
};

}  // namespace espy

#endif  // ESPY_SERVER_STEAM_STEAM_LIBRARY_HPP_
