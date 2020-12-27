#include "igdb/igdb_parser.hpp"

#define CATCH_CONFIG_MAIN
#include <catch.hpp>
#include <nlohmann/json.hpp>

#include "util/test_util.hpp"

namespace espy {

using json = nlohmann::json;

TEST_CASE("[IgdbParser] ParseOAuthResponse parsing responses from IGDB API.",
          "[IgdbParser]") {
  IgdbParser parser;

  SECTION("Token returned") {
    const json obj = {
        {"access_token", "a54acv53fgjcow6h"},
    };

    auto result = parser.ParseOAuthResponse(obj.dump());
    REQUIRE(result.ok());
    REQUIRE(*result == "a54acv53fgjcow6h");
  }

  SECTION("No response") {
    const json obj = {};

    auto result = parser.ParseOAuthResponse(obj.dump());
    REQUIRE(!result.ok());
    REQUIRE(absl::IsNotFound(result.status()));
  }
}

}  // namespace espy
