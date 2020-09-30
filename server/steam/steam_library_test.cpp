#include "steam/steam_library.hpp"

#define CATCH_CONFIG_MAIN
#include <catch.hpp>
#include <absl/status/statusor.h>
#include <absl/strings/str_cat.h>

#include "util/test_file_util.hpp"
#include "util/test_util.hpp"

namespace espy {

namespace {
constexpr char kTestLibraryFile[] = "test_library";

// Poor man's mocking.
class MockSteamService : public SteamService {
 public:
  MockSteamService() : SteamService("app_key", "user_id") {}

  absl::StatusOr<SteamList> GetOwnedGames() const override {
    return steam_list_;
  }

  SteamList& steam_list() { return steam_list_; }

 private:
  SteamList steam_list_;
};

class MockReconciliationService : public ReconciliationService {
 public:
  MockReconciliationService() : ReconciliationService(nullptr) {}

  absl::StatusOr<ReconciliationResult> Reconcile(
      std::vector<SteamEntry> entries) const override {
    REQUIRE(entries.size() == expected_input_size);
    return result_;
  }

  MockReconciliationService& ExpectInputSize(int size) {
    expected_input_size = size;
    return *this;
  }

  ReconciliationResult& result() { return result_; }

 private:
  ReconciliationResult result_;
  int expected_input_size = 0;
};
}  // namespace

TEST_CASE("[SteamLibrary] Load a new Steam library.", "[SteamLibrary]") {
  test::TestFiles test_files;

  MockSteamService mock_steam_service;
  MockReconciliationService mock_reconciler;
  auto library = SteamLibrary::Create(test_files.GetFullPath(kTestLibraryFile),
                                      &mock_steam_service, &mock_reconciler);

  SECTION("Match all games in library") {
    mock_steam_service.steam_list() = test::ParseProto<SteamList>(R"(
      game {
        id: 1
        title: 'Diablo'
      }
      game {
        id: 7
        title: 'Diablo 2'
      })");
    GameList game_list = test::ParseProto<GameList>(R"(
      game {
        id: 123
        title: 'Diablo'
        steam_id: 1
      }
      game {
        id: 234
        title: 'Diablo II'
        steam_id: 7
      })");
    mock_reconciler.ExpectInputSize(2).result().game_list = game_list;

    library->Sync();
    REQUIRE_THAT(library->games(), test::EqualsProto(game_list));
  }

  SECTION("Match only some games in library") {
    mock_steam_service.steam_list() = test::ParseProto<SteamList>(R"(
        game {
          id: 1
          title: 'Diablo'
        }
        game {
          id: 12
          title: 'Diablo 4 Demo'
        }
        game {
          id: 7
          title: 'Diablo 2'
        })");
    GameList game_list = test::ParseProto<GameList>(R"(
        game {
          id: 123
          title: 'Diablo'
          steam_id: 1
        }
        game {
          id: 234
          title: 'Diablo II'
          steam_id: 7
        })");
    mock_reconciler.ExpectInputSize(3).result().game_list = game_list;

    library->Sync();
    REQUIRE_THAT(library->games(), test::EqualsProto(game_list));
  }

  SECTION("Match no game in library") {
    mock_steam_service.steam_list() = test::ParseProto<SteamList>(R"(
        game {
          id: 12
          title: 'Diablo 4 Demo'
        })");
    GameList game_list;
    mock_reconciler.ExpectInputSize(1).result().game_list = game_list;

    library->Sync();
    REQUIRE_THAT(library->games(), test::EqualsProto(game_list));
  }

  SECTION("No games returned") {
    mock_steam_service.steam_list() = SteamList();
    GameList game_list;
    // NOTE: Poor man's way of verifying this is not called. The negative
    // input size would always trigger an assertion if called.
    mock_reconciler.ExpectInputSize(-1);

    library->Sync();
    REQUIRE_THAT(library->games(), test::EqualsProto(game_list));
  }
}

TEST_CASE("[SteamLibrary] Load & sync an existing Steam library.",
          "[SteamLibrary]") {
  constexpr char kTestLibraryFile[] = "test_library";

  test::TestFiles test_files;
  test_files.SaveProtoTestFile(test::ParseProto<GameList>(R"(
                                  game {
                                    id: 123
                                    title: 'Diablo'
                                    steam_id: 1
                                  })"),
                               kTestLibraryFile);

  MockSteamService mock_steam_service;
  MockReconciliationService mock_reconciler;
  auto library = SteamLibrary::Create(test_files.GetFullPath(kTestLibraryFile),
                                      &mock_steam_service, &mock_reconciler);

  SECTION("Match all games in library") {
    mock_steam_service.steam_list() = test::ParseProto<SteamList>(R"(
      game {
        id: 1
        title: 'Diablo'
      }
      game {
        id: 7
        title: 'Diablo 2'
      })");

    mock_reconciler.ExpectInputSize(1).result().game_list =
        test::ParseProto<GameList>(R"(
          game {
            id: 234
            title: 'Diablo II'
            steam_id: 7
          })");

    library->Sync();
    REQUIRE_THAT(library->games(),
                 test::EqualsProto(test::ParseProto<GameList>(R"(
                    game {
                      id: 123
                      title: 'Diablo'
                      steam_id: 1
                    }
                    game {
                      id: 234
                      title: 'Diablo II'
                      steam_id: 7
                    })")));
  }

  SECTION("Match only some games in library") {
    mock_steam_service.steam_list() = test::ParseProto<SteamList>(R"(
        game {
          id: 1
          title: 'Diablo'
        }
        game {
          id: 12
          title: 'Diablo 4 Demo'
        }
        game {
          id: 7
          title: 'Diablo 2'
        })");
    mock_reconciler.ExpectInputSize(2).result().game_list =
        test::ParseProto<GameList>(R"(
          game {
            id: 234
            title: 'Diablo II'
            steam_id: 7
          })");

    library->Sync();
    REQUIRE_THAT(library->games(),
                 test::EqualsProto(test::ParseProto<GameList>(R"(
                    game {
                      id: 123
                      title: 'Diablo'
                      steam_id: 1
                    }
                    game {
                      id: 234
                      title: 'Diablo II'
                      steam_id: 7
                    })")));
  }

  SECTION("No new games from sync in library") {
    mock_steam_service.steam_list() = test::ParseProto<SteamList>(R"(
      game {
        id: 1
        title: 'Diablo'
      })");

    // NOTE: Poor man's way of verifying this is not called. The negative
    // input size would always trigger an assertion if called.
    mock_reconciler.ExpectInputSize(-1);

    library->Sync();
    REQUIRE_THAT(library->games(),
                 test::EqualsProto(test::ParseProto<GameList>(R"(
                    game {
                      id: 123
                      title: 'Diablo'
                      steam_id: 1
                    })")));
  }

  SECTION("Match no game in library") {
    mock_steam_service.steam_list() = test::ParseProto<SteamList>(R"(
        game {
          id: 12
          title: 'Diablo 4 Demo'
        })");
    GameList game_list;
    mock_reconciler.ExpectInputSize(1).result().game_list = game_list;

    library->Sync();
    REQUIRE_THAT(library->games(),
                 test::EqualsProto(test::ParseProto<GameList>(R"(
                    game {
                      id: 123
                      title: 'Diablo'
                      steam_id: 1
                    })")));
  }

  SECTION("No games returned") {
    mock_steam_service.steam_list() = SteamList();
    GameList game_list;
    // NOTE: Poor man's way of verifying this is not called. The negative
    // input size would always trigger an assertion if called.
    mock_reconciler.ExpectInputSize(-1);

    library->Sync();
    REQUIRE_THAT(library->games(),
                 test::EqualsProto(test::ParseProto<GameList>(R"(
                    game {
                      id: 123
                      title: 'Diablo'
                      steam_id: 1
                    })")));
  }
}

}  // namespace espy
