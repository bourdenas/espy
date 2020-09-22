#include "igdb/igdb_parser.hpp"

#define CATCH_CONFIG_MAIN
#include <catch.hpp>
#include <nlohmann/json.hpp>

#include "util/test_util.hpp"

namespace espy {

using json = nlohmann::json;

TEST_CASE("[IgdbParser] SearchByTitle parsing responses from IGDB API.",
          "[IgdbParser]") {
  IgdbParser parser;

  SECTION("Single match") {
    const json obj = {
        {{"id", 1234}, {"name", "Foo"}},
    };

    auto result = parser.ParseSearchByTitleResponse(obj.dump());
    REQUIRE(result.ok());
    REQUIRE_THAT(*result,
                 test::EqualsProto(test::ParseProto<igdb::SearchResultList>(R"(
                  result {
                    id: 1234
                    title: 'Foo'
                  })")));
  }

  SECTION("Multiple results") {
    const json obj = {
        {{"id", 1234}, {"name", "Foo"}},
        {{"id", 2345}, {"name", "Bar"}},
        {{"id", 3456}, {"name", "Yak"}},
    };

    auto result = parser.ParseSearchByTitleResponse(obj.dump());
    REQUIRE(result.ok());
    REQUIRE_THAT(*result,
                 test::EqualsProto(test::ParseProto<igdb::SearchResultList>(R"(
                  result {
                    id: 1234
                    title: 'Foo'
                  }
                  result {
                    id: 2345
                    title: 'Bar'
                  }
                  result {
                    id: 3456
                    title: 'Yak'
                  })")));
  }

  SECTION("No matches") {
    const json obj = {};

    auto result = parser.ParseSearchByTitleResponse(obj.dump());
    REQUIRE(result.ok());
    REQUIRE_THAT(*result, test::EqualsProto(igdb::SearchResultList()));
  }

  SECTION("Malformed response") {
    // Bad JSON syntax; missing comma.
    const auto malformed_response = R"([
      {
        "id": 1234
        "name": "Foo"
      }
    ])";

    auto result = parser.ParseSearchByTitleResponse(malformed_response);
    REQUIRE(absl::IsInvalidArgument(result.status()));
  }

  SECTION("Response with missing fields") {
    json obj = {
        {{"id", 1234}, {"name", "Foo"}},
        {{"name", "Bar"}},
        {{"id", 3456}, {"name", "Yak"}},
    };
    auto result = parser.ParseSearchByTitleResponse(obj.dump());
    REQUIRE(absl::IsInvalidArgument(result.status()));

    obj = {
        {{"id", 1234}, {"name", "Foo"}},
        {{"id", 2345}, {"name", "Bar"}},
        {{"id", 3456}},
    };
    result = parser.ParseSearchByTitleResponse(obj.dump());
    REQUIRE(absl::IsInvalidArgument(result.status()));
  }

  SECTION("Bad field type response") {
    json obj = {
        {{"id", "1234"}, {"name", "Foo"}},
        {{"id", 2345}, {"name", "Bar"}},
        {{"id", 3456}, {"name", "Yak"}},
    };
    auto result = parser.ParseSearchByTitleResponse(obj.dump());
    REQUIRE(absl::IsInvalidArgument(result.status()));

    obj = {
        {{"id", 1234}, {"name", "Foo"}},
        {{"id", 2345}, {"name", {}}},
        {{"id", 3456}, {"name", "Yak"}},
    };
    result = parser.ParseSearchByTitleResponse(obj.dump());
    REQUIRE(absl::IsInvalidArgument(result.status()));
  }
}

}  // namespace espy
