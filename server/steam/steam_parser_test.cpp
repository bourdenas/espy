#include "steam/steam_parser.hpp"

#define CATCH_CONFIG_MAIN
#include <catch.hpp>
#include <nlohmann/json.hpp>

#include "util/test_util.hpp"

namespace espy {

using json = nlohmann::json;

TEST_CASE("[SteamParser] GetOwnedGames parsing responses from Steam API.",
          "[SteamParser]") {
  SteamParser parser;

  SECTION("Single Game") {
    const json obj = {{"response",
                       {{"game_count", 1},
                        {
                            "games",
                            {
                                {{"appid", 1234}, {"name", "Foo"}},
                            },
                        }}}};

    auto result = parser.ParseGetOwnedGames(obj.dump());
    REQUIRE(result.ok());
    REQUIRE_THAT(*result, test::EqualsProto(test::ParseProto<GameList>(R"(
                  game {
                    title: 'Foo'
                    steam_id: 1234
                  })")));
  }

  SECTION("Many Games") {
    const json obj = {{"response",
                       {{"game_count", 3},
                        {
                            "games",
                            {
                                {{"appid", 1234}, {"name", "Foo"}},
                                {{"appid", 2345}, {"name", "Bar"}},
                                {{"appid", 3456}, {"name", "Yak"}},
                            },
                        }}}};

    auto result = parser.ParseGetOwnedGames(obj.dump());
    REQUIRE(result.ok());
    REQUIRE_THAT(*result, test::EqualsProto(test::ParseProto<GameList>(R"(
                  game {
                    title: 'Foo'
                    steam_id: 1234
                  }
                  game {
                    title: 'Bar'
                    steam_id: 2345
                  }
                  game {
                    title: 'Yak'
                    steam_id: 3456
                  })")));
  }

  SECTION("No Games") {
    const json obj = {{"response",
                       {
                           {"game_count", 0},
                       }}};

    auto result = parser.ParseGetOwnedGames(obj.dump());
    REQUIRE(result.ok());
    REQUIRE_THAT(*result, test::EqualsProto(GameList()));
  }

  SECTION("Empty response") {
    const json obj = {};

    auto result = parser.ParseGetOwnedGames(obj.dump());
    REQUIRE(result.ok());
    REQUIRE_THAT(*result, test::EqualsProto(GameList()));
  }

  SECTION("Malformed response") {
    const auto malformed_response = R"({
      response: {
        "game_count": 1,
        "games": [{
          "appid": 1234,
          "name": "Foo"
        }]
      }
    })";

    auto result = parser.ParseGetOwnedGames(malformed_response);
    REQUIRE(absl::IsInvalidArgument(result.status()));
  }

  SECTION("Missing fields response") {
    json obj = {{"response",
                 {{"game_count", 1},
                  {
                      "games",
                      {
                          {{"appid", 1234}},
                      },
                  }}}};

    auto result = parser.ParseGetOwnedGames(obj.dump());
    REQUIRE(absl::IsInvalidArgument(result.status()));

    obj = {{"response",
            {{"game_count", 1},
             {
                 "games",
                 {
                     {{"name", "Foo"}},
                 },
             }}}};

    result = parser.ParseGetOwnedGames(obj.dump());
    REQUIRE(absl::IsInvalidArgument(result.status()));
  }

  SECTION("Bad field type response") {
    json obj = {{"response",
                 {{"game_count", 1},
                  {
                      "games",
                      {
                          {{"appid", "1234"}, {"name", {}}},
                      },
                  }}}};

    auto result = parser.ParseGetOwnedGames(obj.dump());
    REQUIRE(absl::IsInvalidArgument(result.status()));

    obj = {{"response",
            {
                {"game_count", 1},
                {"games", 3},
            }}};

    result = parser.ParseGetOwnedGames(obj.dump());
    REQUIRE(absl::IsInvalidArgument(result.status()));
  }
}

}  // namespace espy
