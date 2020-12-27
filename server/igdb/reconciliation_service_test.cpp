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

  absl::StatusOr<igdb::GameResult> SearchByTitle(
      std::string_view title) const override {
    if (title == "") {
      return absl::NotFoundError("blah");
    } else if (title == "Diablo") {
      return test::ParseProto<igdb::GameResult>(R"(
        games {
          id: 1210
          name: 'Diablo'
        }
        games {
          id: 1212
          name: 'Diablo II'
        })");
    } else if (title == "Diablo 2") {
      return test::ParseProto<igdb::GameResult>(R"(
        games {
          id: 1212
          name: 'Diablo II'
        })");
    }
    return absl::InvalidArgumentError(
        absl::StrCat("Unexpected call to MockIgdbService::SearchByTitle('",
                     std::string(title), "')"));
  }

  absl::StatusOr<igdb::Cover> GetCover(int64_t cover_id) const override {
    return absl::UnimplementedError("not yet");
  }

  absl::StatusOr<igdb::FranchiseResult> GetFranchises(
      const std::vector<int64_t>& franchise_ids) const override {
    return absl::UnimplementedError("not yet");
  }

  absl::StatusOr<igdb::Collection> GetCollection(
      int64_t collection_id) const override {
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

    auto library = reconciler.Reconcile(entries);
    REQUIRE(library.ok());

    REQUIRE_THAT(*library, test::EqualsProto(test::ParseProto<Library>(R"(
                              entry {
                                game {
                                  id: 1212
                                  name: 'Diablo II'
                                }
                                store_owned {
                                  game_id: 1234
                                  store_id: 1
                                }
                              })")));
  }

  SECTION("Multiple matches") {
    std::vector<SteamEntry> entries = {
        test::ParseProto<SteamEntry>(R"(
          id: 123
          title: 'Diablo'
        )"),
    };

    auto library = reconciler.Reconcile(entries);
    REQUIRE(library.ok());

    REQUIRE_THAT(*library, test::EqualsProto(test::ParseProto<Library>(R"(
                              entry {
                                game {
                                  id: 1210
                                  name: 'Diablo'
                                }
                                store_owned {
                                  game_id: 123
                                  store_id: 1
                                }
                              })")));
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

    auto library = reconciler.Reconcile(entries);
    REQUIRE(library.ok());

    REQUIRE_THAT(*library, test::EqualsProto(test::ParseProto<Library>(R"(
                              entry {
                                game {
                                  id: 1210
                                  name: 'Diablo'
                                }
                                store_owned {
                                  game_id: 123
                                  store_id: 1
                                }
                              }
                              entry {
                                game {
                                  id: 1212
                                  name: 'Diablo II'
                                }
                                store_owned {
                                  game_id: 125
                                  store_id: 1
                                }
                              }
                              unreconciled_steam_game {
                                id: 127
                                title: 'Diablo 4'
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

    auto library = reconciler.Reconcile(entries);
    REQUIRE(library.ok());
    REQUIRE_THAT(*library, test::EqualsProto(test::ParseProto<Library>(R"(
                  unreconciled_steam_game {
                    id: 12345
                    title: ''
                  }
                  unreconciled_steam_game {
                    id: 123
                    title: 'foo'
                  })")));
  }

  SECTION("No input entries") {
    auto library = reconciler.Reconcile({});
    REQUIRE(library.ok());
    REQUIRE_THAT(*library, test::EqualsProto(test::ParseProto<Library>("")));
  }
}

}  // namespace espy
