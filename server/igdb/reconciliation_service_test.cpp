#include "igdb/reconciliation_service.hpp"

#define CATCH_CONFIG_MAIN
#include <catch.hpp>
#include <absl/status/statusor.h>
#include <absl/strings/str_cat.h>

#include "util/test_util.hpp"

namespace espy {

namespace {
// Poor man's mocking.
class MockIgdbService : public IgdbService {
 public:
  MockIgdbService() : IgdbService("", "") {}

  absl::StatusOr<igdb::SearchResultList> SearchByTitle(
      std::string_view title) const override {
    if (title == "") {
      return absl::NotFoundError("blah");
    } else if (title == "Diablo") {
      return test::ParseProto<igdb::SearchResultList>(R"(
        result {
          id: 1210
          title: 'Diablo'
        }
        result {
          id: 1212
          title: 'Diablo II'
        })");
    } else if (title == "Diablo 2") {
      return test::ParseProto<igdb::SearchResultList>(R"(
        result {
          id: 1212
          title: 'Diablo II'
        })");
    }
    return absl::InvalidArgumentError(
        absl::StrCat("Unexpected call to MockIgdbService::SearchByTitle('",
                     std::string(title), "')"));
  }

  absl::StatusOr<std::string> GetCover(int64_t cover_id) const override {
    return absl::UnimplementedError("not yet");
  }

  absl::StatusOr<std::vector<Franchise>> GetFranchises(
      const std::vector<int64_t>& franchise_ids) const override {
    return absl::UnimplementedError("not yet");
  }

  absl::StatusOr<Franchise> GetSeries(int64_t collection_id) const override {
    return absl::UnimplementedError("not yet");
  }
};
}  // namespace

TEST_CASE("[ReconciliationService] Reconcile games by title using IgdbService.",
          "[ReconciliationService]") {
  MockIgdbService mock;
  ReconciliationService reconciler(&mock);

  SECTION("Single match") {
    std::vector<SteamEntry> entries = {
        test::ParseProto<SteamEntry>(R"(
          id: 1234
          title: 'Diablo 2'
        )"),
    };

    auto result = reconciler.Reconcile(entries);
    REQUIRE(result.ok());

    REQUIRE_THAT(result->game_list,
                 test::EqualsProto(test::ParseProto<GameList>(R"(
                  game {
                    id: 1212
                    title: 'Diablo II'
                    steam_id: 1234
                  })")));
    REQUIRE(result->unreconciled.task().empty());
  }

  SECTION("Multiple matches") {
    std::vector<SteamEntry> entries = {
        test::ParseProto<SteamEntry>(R"(
          id: 123
          title: 'Diablo'
        )"),
    };

    auto result = reconciler.Reconcile(entries);
    REQUIRE(result.ok());

    REQUIRE_THAT(result->game_list,
                 test::EqualsProto(test::ParseProto<GameList>(R"(
                  game {
                    id: 1210
                    title: 'Diablo'
                    steam_id: 123
                  })")));
    REQUIRE(result->unreconciled.task().empty());
  }

  SECTION("Multiple game entries") {
    std::vector<SteamEntry> entries = {
        test::ParseProto<SteamEntry>(R"(
          id: 123
          title: 'Diablo'
        )"),
        test::ParseProto<SteamEntry>(R"(
          id: 125
          title: 'Diablo 2'
        )"),
        test::ParseProto<SteamEntry>(R"(
          id: 127
          title: 'Diablo 4'
        )"),
    };

    auto result = reconciler.Reconcile(entries);
    REQUIRE(result.ok());

    REQUIRE_THAT(result->game_list,
                 test::EqualsProto(test::ParseProto<GameList>(R"(
                  game {
                    id: 1210
                    title: 'Diablo'
                    steam_id: 123
                  }
                  game {
                    id: 1212
                    title: 'Diablo II'
                    steam_id: 125
                  })")));
    REQUIRE_THAT(result->unreconciled,
                 test::EqualsProto(test::ParseProto<ReconciliationTaskList>(R"(
                  task {
                    steam_entry {
                      id: 127
                      title: 'Diablo 4'
                    }
                  })")));
  }

  SECTION("No matches") {
    std::vector<SteamEntry> entries = {
        test::ParseProto<SteamEntry>(R"(
          id: 12345
          title: ''
        )"),
        test::ParseProto<SteamEntry>(R"(
          id: 123
          title: 'foo'
        )"),
    };

    auto result = reconciler.Reconcile(entries);
    REQUIRE(result.ok());
    REQUIRE(result->game_list.game().empty());
    REQUIRE_THAT(result->unreconciled,
                 test::EqualsProto(test::ParseProto<ReconciliationTaskList>(R"(
                  task {
                    steam_entry {
                      id: 12345
                      title: ''
                    }
                  }
                  task {
                    steam_entry {
                      id: 123
                      title: 'foo'
                    }
                  })")));
  }

  SECTION("No input entries") {
    auto result = reconciler.Reconcile({});
    REQUIRE(result.ok());
    REQUIRE(result->game_list.game().empty());
    REQUIRE(result->unreconciled.task().empty());
  }
}

}  // namespace espy
