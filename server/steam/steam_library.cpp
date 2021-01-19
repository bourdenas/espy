#include "steam/steam_library.hpp"

#include <execution>
#include <future>
#include <unordered_set>

#include <glog/logging.h>

#include "util/proto_util.hpp"

namespace espy {

absl::StatusOr<SteamLibrary> SteamLibrary::Create(
    std::string espy_user_id, const SteamService* steam_service,
    const ReconciliationService* reconciliation_service) {
  auto lib = SteamLibrary(std::move(espy_user_id), steam_service,
                          reconciliation_service);

  auto result =
      util::LoadProto<Library>(absl::StrCat(lib.espy_user_id_, ".bin"));
  if (result.ok()) {
    lib.library_ = std::move(result.value());
  }

  return lib;
}

absl::Status SteamLibrary::Sync() {
  auto promise = std::async(
      std::launch::async, [this]() { return steam_service_->GetOwnedGames(); });

  std::unordered_set<int64_t> steam_ids;
  std::transform(library_.entry().begin(), library_.entry().end(),
                 std::inserter(steam_ids, steam_ids.begin()),
                 [](const GameEntry& entry) {
                   for (const auto& store : entry.store_owned()) {
                     if (store.store_id() == GameEntry::Store::STEAM) {
                       return store.game_id();
                     }
                   }
                   return static_cast<int64_t>(0);
                 });

  auto steam_response = promise.get();
  if (!steam_response.ok()) {
    return steam_response.status();
  }

  SteamList& games = steam_response.value();
  std::vector<SteamEntry> unreconciled;
  std::copy_if(games.game().begin(), games.game().end(),
               std::back_inserter(unreconciled),
               [&steam_ids](const SteamEntry& entry) {
                 return !steam_ids.contains(entry.id());
               });

  if (unreconciled.empty()) {
    return absl::OkStatus();
  }

  auto library = reconciler_->Reconcile(unreconciled);
  if (!library.ok()) {
    return library.status();
  }
  library_.mutable_entry()->MergeFrom(library->entry());
  *library_.mutable_unreconciled_steam_game() = {
      library->unreconciled_steam_game().begin(),
      library->unreconciled_steam_game().end()};
  util::SaveProto(library_, espy_user_id_);

  return absl::OkStatus();
}

}  // namespace espy
