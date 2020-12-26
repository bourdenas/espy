#include "igdb/igdb_parser.hpp"

#include <optional>
#include <ranges>

#include <absl/strings/str_cat.h>
#include <glog/logging.h>
#include <nlohmann/json.hpp>

namespace espy {

using json = nlohmann::json;

namespace {
absl::StatusOr<int> GetInt(const json& obj, std::string_view field_name) {
  const auto it = obj.find(field_name);
  if (it == obj.end() || !it->is_number_integer()) {
    return absl::NotFoundError(
        absl::StrCat("Game in response has no '", std::string(field_name),
                     "' field or its type is not Integer."));
  }
  return it->get<int>();
}

absl::StatusOr<std::string> GetString(const json& obj,
                                      std::string_view field_name) {
  const auto it = obj.find(field_name);
  if (it == obj.end() || !it->is_string()) {
    return absl::NotFoundError(
        absl::StrCat("Game in response has no '", std::string(field_name),
                     "' field or its type is not String."));
  }
  return it->get<std::string>();
}

std::optional<int> GetOptionalInt(const json& obj,
                                  std::string_view field_name) {
  const auto it = obj.find(field_name);
  if (it == obj.end() || !it->is_number_integer()) {
    return std::nullopt;
  }
  return it->get<int>();
}

std::optional<std::vector<int>> GetOptionalIntVector(
    const json& obj, std::string_view field_name) {
  const auto it = obj.find(field_name);
  if (it == obj.end() || !it->is_array()) {
    return std::nullopt;
  }
  std::vector<int> vec;
  for (const auto& e : *it) {
    if (!e.is_number_integer()) {
      LOG(WARNING) << "Unexpected type found in expected integer array: "
                   << obj.dump();
      return std::nullopt;
    }
    vec.push_back(e.get<int>());
  }
  return vec;
}

std::optional<std::string> GetOptionalString(const json& obj,
                                             std::string_view field_name) {
  const auto it = obj.find(field_name);
  if (it == obj.end() || !it->is_string()) {
    return std::nullopt;
  }
  return it->get<std::string>();
}
}  // namespace

absl::StatusOr<std::string> IgdbParser::ParseOAuthResponse(
    std::string_view json_response) const {
  auto json_obj = json::parse(json_response, nullptr, false);
  if (json_obj.is_discarded()) {
    return absl::InvalidArgumentError(
        absl::StrCat("Failed to parse JSON response from Twitch.OAuth2\n",
                     std::string(json_response)));
  }

  return GetString(json_obj, "access_token");
}

absl::StatusOr<igdb::SearchResultList> IgdbParser::ParseSearchByTitleResponse(
    std::string_view json_response) const {
  igdb::SearchResultList search_result_list;

  auto json_obj = json::parse(json_response, nullptr, false);
  if (json_obj.is_discarded()) {
    return absl::InvalidArgumentError(
        absl::StrCat("Failed to parse JSON response from IGDB.SearchByTitle\n",
                     std::string(json_response)));
  }

  for (const auto& game : json_obj) {
    auto* result = search_result_list.add_result();

    auto id = GetInt(game, "id");
    if (!id.ok()) {
      return absl::InvalidArgumentError(
          absl::StrCat(id.status().message(), "\nJSON object: ", game.dump()));
    }
    result->set_id(*id);

    auto name = GetString(game, "name");
    if (!name.ok()) {
      return absl::InvalidArgumentError(absl::StrCat(
          name.status().message(), "\nJSON object: ", game.dump()));
    }
    result->set_title(*name);

    auto url = GetString(game, "url");
    if (!url.ok()) {
      return absl::InvalidArgumentError(
          absl::StrCat(url.status().message(), "\nJSON object: ", game.dump()));
    }
    result->set_url(*url);

    auto cover = GetOptionalInt(game, "cover");
    if (cover != std::nullopt) {
      result->set_cover_id(*cover);
    }

    auto franchise = GetOptionalInt(game, "franchise");
    if (franchise != std::nullopt) {
      result->add_franchise_id(*franchise);
    }

    auto franchises = GetOptionalIntVector(game, "franchises");
    if (franchises != std::nullopt) {
      for (int id : *franchises) {
        result->add_franchise_id(id);
      }
    }

    auto collection = GetOptionalInt(game, "collection");
    if (collection != std::nullopt) {
      result->set_collection_id(*collection);
    }

    auto release_date = GetOptionalInt(game, "first_release_date");
    if (release_date != std::nullopt) {
      result->set_release_date(*release_date);
    }
  }

  return search_result_list;
}

absl::StatusOr<std::string> IgdbParser::ParseGetCoverResponse(
    std::string_view json_response) const {
  auto json_obj = json::parse(json_response, nullptr, false);
  if (json_obj.is_discarded()) {
    return absl::InvalidArgumentError(
        absl::StrCat("Failed to parse JSON response from IGDB.GetCover\n",
                     std::string(json_response)));
  }

  for (const auto& result : json_obj) {
    if (auto image_id = GetOptionalString(result, "image_id");
        image_id != std::nullopt) {
      return *image_id;
    }
  }
  return absl::NotFoundError("No cover result returned.");
}

absl::StatusOr<std::vector<Franchise>> IgdbParser::ParseGetFranchiseResponse(
    std::string_view json_response) const {
  auto json_obj = json::parse(json_response, nullptr, false);
  if (json_obj.is_discarded()) {
    return absl::InvalidArgumentError(
        absl::StrCat("Failed to parse JSON response from IGDB.GetFranchise\n",
                     std::string(json_response)));
  }

  std::vector<Franchise> franchises;
  std::transform(json_obj.begin(), json_obj.end(),
                 std::back_inserter(franchises), [](const auto& result) {
                   Franchise franchise;
                   auto id = GetInt(result, "id");
                   if (id.ok()) {
                     franchise.set_id(std::move(*id));
                   }

                   auto name = GetString(result, "name");
                   if (name.ok()) {
                     franchise.set_name(std::move(*name));
                   }

                   auto url = GetString(result, "url");
                   if (url.ok()) {
                     franchise.set_url(std::move(*url));
                   }

                   return franchise;
                 });

  return franchises;
}

}  // namespace espy
