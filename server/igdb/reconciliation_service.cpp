#include "igdb/reconciliation_service.hpp"

#include <algorithm>
#include <execution>

#include <glog/logging.h>

#include "util/qps_rate_limiter.hpp"

namespace espy {

namespace {
// Returns edit distance between two strings.
int EditDistance(std::string_view a, std::string_view b) {
  std::vector<int> matrix((a.size() + 1) * (b.size() + 1));
  const auto row_size = b.size() + 1;
  matrix[0] = 0;

  // Translate 2d coordinates to a single-dimensional array.
  auto xy = [row_size](int x, int y) { return x * row_size + y; };

  for (int i = 1; i <= a.size(); ++i) {
    matrix[xy(i, 0)] = i;
  }

  for (int i = 1; i <= b.size(); ++i) {
    matrix[xy(0, i)] = i;
  }

  int cost = 0;
  for (int i = 1; i <= a.size(); ++i) {
    for (int j = 1; j <= b.size(); ++j) {
      cost = a[i - 1] == b[j - 1] ? 0 : 1;
      matrix[xy(i, j)] = std::min<int>(
          std::min<int>(matrix[xy(i - 1, j)] + 1, matrix[xy(i, j - 1)] + 1),
          matrix[xy(i - 1, j - 1)] + cost);
    }
  }
  return matrix.back();
}

constexpr int kIgdbQps = 4;

}  // namespace

absl::StatusOr<Library> ReconciliationService::Reconcile(
    std::vector<SteamEntry> entries) const {
  // IGDB API imposes a QPS limit.
  QpsRateLimiter qps_rate(kIgdbQps);

  std::vector<ReconciliationTask> reconciliation_tasks(entries.size());
  std::transform(
      std::execution::par, entries.begin(), entries.end(),
      reconciliation_tasks.begin(), [this, &qps_rate](SteamEntry& entry) {
        DLOG(INFO) << "Reconciling '" << entry.title() << "'";

        ReconciliationTask task;
        *task.mutable_steam_entry() = std::move(entry);

        qps_rate.Wait();
        auto game_result =
            igdb_service_->SearchByTitle(task.steam_entry().title());
        if (!game_result.ok()) {
          DLOG(WARNING) << "Failed to retrieve info for\n"
                        << task.steam_entry().DebugString()
                        << "Error: " << game_result.status();
          return task;
        }

        std::transform(
            game_result->mutable_games()->begin(),
            game_result->mutable_games()->end(),
            google::protobuf::RepeatedFieldBackInserter(
                task.mutable_candidate()),
            [&task](igdb::Game& game) {
              ReconciliationCandidate candidate;
              *candidate.mutable_game() = std::move(game);
              candidate.set_score(EditDistance(task.steam_entry().title(),
                                               candidate.game().name()));
              return candidate;
            });

        std::sort(task.mutable_candidate()->begin(),
                  task.mutable_candidate()->end(),
                  [](const ReconciliationCandidate& left,
                     const ReconciliationCandidate& right) {
                    return left.score() < right.score();
                  });

        return task;
      });

  const auto it = std::partition(
      reconciliation_tasks.begin(), reconciliation_tasks.end(),
      [](const ReconciliationTask& task) { return task.candidate_size() > 0; });

  // Acrobatics to resize protobuf repeated field for parallel execution.
  const auto library_size = std::distance(reconciliation_tasks.begin(), it);
  Library library;
  library.mutable_entry()->Reserve(static_cast<int>(library_size));
  for (int i = 0; i < library_size; ++i) library.add_entry();

  std::transform(
      std::execution::par, reconciliation_tasks.begin(), it,
      library.mutable_entry()->begin(),
      [this, &qps_rate](ReconciliationTask& task) {
        const igdb::Game& top_result = task.candidate(0).game();

        GameEntry entry;
        *entry.mutable_game() =
            std::move(*task.mutable_candidate(0)->mutable_game());
        auto* store = entry.add_store_owned();
        store->set_game_id(task.steam_entry().id());
        store->set_store_id(GameEntry::Store::STEAM);

        if (entry.game().cover().id() > 0) {
          qps_rate.Wait();
          auto cover_result =
              igdb_service_->GetCover(entry.game().cover().id());
          if (cover_result.ok()) {
            *entry.mutable_game()->mutable_cover() = std::move(*cover_result);
          }
        }

        if (!entry.game().franchises().empty()) {
          qps_rate.Wait();
          std::vector<int64_t> franchise_ids;
          for (const auto& franchise : entry.game().franchises()) {
            franchise_ids.push_back(franchise.id());
          }

          auto franchise_result = igdb_service_->GetFranchises(franchise_ids);
          if (franchise_result.ok()) {
            *entry.mutable_game()->mutable_franchises() =
                std::move(*franchise_result->mutable_franchises());
          }
        }

        if (entry.game().collection().id() > 0) {
          qps_rate.Wait();
          auto collection_result =
              igdb_service_->GetCollection(entry.game().collection().id());
          if (collection_result.ok()) {
            *entry.mutable_game()->mutable_collection() =
                std::move(*collection_result);
          }
        }
        return entry;
      });
  std::transform(
      it, reconciliation_tasks.end(),
      google::protobuf::RepeatedFieldBackInserter(
          library.mutable_unreconciled_steam_game()),
      [](const ReconciliationTask& task) { return task.steam_entry(); });

  return library;
}

}  // namespace espy
