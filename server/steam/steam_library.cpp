#include "steam/steam_library.hpp"

#include <execution>
#include <future>
#include <ranges>
#include <unordered_set>

#include <glog/logging.h>

#include "util/proto_util.hpp"

namespace espy {

absl::StatusOr<SteamLibrary> SteamLibrary::Create(
    std::string espy_user_id, const SteamService* steam_service,
    const ReconciliationService* reconciliation_service) {
  auto lib = SteamLibrary(std::move(espy_user_id), steam_service,
                          reconciliation_service);

  auto result = espy::util::LoadProto<espy::GameList>(
      absl::StrCat(lib.espy_user_id_, ".bin"));
  if (result.ok()) {
    lib.game_list_ = std::move(result.value());
  }

  return lib;
}

absl::Status SteamLibrary::Sync() {
  auto promise = std::async(
      std::launch::async, [this]() { return steam_service_->GetOwnedGames(); });

  std::unordered_set<int64_t> steam_ids;
  for (const auto& entry : game_list_.game()) {
    steam_ids.insert(entry.steam_id());
  }

  auto steam_response = promise.get();
  if (!steam_response.ok()) {
    return steam_response.status();
  }

  SteamList& games = steam_response.value();
  auto&& unreconciled_range =
      games.game() | std::views::filter([&steam_ids](const SteamEntry& entry) {
        return !steam_ids.contains(entry.id());
      });
  std::vector<SteamEntry> unreconciled;
  std::move(unreconciled_range.begin(), unreconciled_range.end(),
            std::back_inserter(unreconciled));

  if (unreconciled.empty()) return absl::OkStatus();

  auto result = reconciler_->Reconcile(unreconciled);
  if (!result.ok()) {
    return result.status();
  }
  game_list_.mutable_game()->MergeFrom(result->game_list.game());

  util::SaveProto(game_list_, espy_user_id_);

  return absl::OkStatus();
}

}  // namespace espy
