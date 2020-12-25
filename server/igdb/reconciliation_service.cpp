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

absl::StatusOr<ReconciliationResult> ReconciliationService::Reconcile(
    std::vector<SteamEntry> entries) const {
  // IGDB API imposes a QPS limit.
  QpsRateLimiter qps_rate(kIgdbQps);

  std::vector<ReconciliationTask> reconciliation_tasks(entries.size());
  std::transform(
      std::execution::par, entries.begin(), entries.end(),
      reconciliation_tasks.begin(), [this, &qps_rate](SteamEntry& entry) {
        qps_rate.Wait();
        DLOG(INFO) << "Reconciling '" << entry.title() << "'";
        auto result = igdb_service_->SearchByTitle(entry.title());

        ReconciliationTask task;
        *task.mutable_steam_entry() = std::move(entry);

        if (!result.ok()) {
          DLOG(WARNING) << "Failed to retrieve info for\n"
                        << task.steam_entry().DebugString()
                        << "Error: " << result.status();
          return task;
        }

        std::transform(result->mutable_result()->begin(),
                       result->mutable_result()->end(),
                       google::protobuf::RepeatedFieldBackInserter(
                           task.mutable_candidate()),
                       [](igdb::SearchResult& search_result) {
                         Candidate candidate;
                         *candidate.mutable_result() = std::move(search_result);
                         return candidate;
                       });

        for (auto& candidate : *task.mutable_candidate()) {
          candidate.set_score(EditDistance(task.steam_entry().title(),
                                           candidate.result().title()));
        }
        std::sort(task.mutable_candidate()->begin(),
                  task.mutable_candidate()->end(),
                  [](const Candidate& left, const Candidate& right) {
                    return left.score() < right.score();
                  });

        return task;
      });

  const auto it = std::partition(
      reconciliation_tasks.begin(), reconciliation_tasks.end(),
      [](const ReconciliationTask& task) { return task.candidate_size() > 0; });

  ReconciliationResult result;
  std::transform(reconciliation_tasks.begin(), it,
                 google::protobuf::RepeatedFieldBackInserter(
                     result.game_list.mutable_game()),
                 [this, &qps_rate](const ReconciliationTask& task) {
                   const auto& top_result = task.candidate(0).result();

                   GameEntry entry;
                   entry.set_id(top_result.id());
                   entry.set_title(top_result.title());
                   entry.set_steam_id(task.steam_entry().id());

                   if (top_result.cover_id() > 0) {
                     qps_rate.Wait();
                     auto result =
                         igdb_service_->GetCover(top_result.cover_id());
                     if (result.ok()) {
                       entry.set_cover_image_id(std::move(*result));
                     }
                   }
                   return entry;
                 });
  std::move(it, reconciliation_tasks.end(),
            google::protobuf::RepeatedFieldBackInserter(
                result.unreconciled.mutable_task()));

  return result;
}

}  // namespace espy
