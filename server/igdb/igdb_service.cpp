#include "igdb/igdb_service.hpp"

#include <memory>
#include <sstream>

#include <absl/strings/str_cat.h>
#include <absl/strings/str_join.h>
#include <curlpp/cURLpp.hpp>
#include <curlpp/Easy.hpp>
#include <curlpp/Options.hpp>
#include <glog/logging.h>

#include "igdb/igdb_parser.hpp"

namespace espy {

constexpr char kTwitchOAuthUrl[] = "https://id.twitch.tv/oauth2/token?";

absl::Status IgdbService::Authenticate() {
  const std::string params =
      absl::StrJoin({absl::StrCat("client_id=", client_id_),
                     absl::StrCat("client_secret=", secret_),
                     std::string("grant_type=client_credentials")},
                    "&");
  const auto url_string = absl::StrCat(kTwitchOAuthUrl, params);
  LOG(INFO) << url_string;
  const auto url = curlpp::options::Url(url_string);

  const std::string empty_body;

  try {
    curlpp::Easy handle;
    handle.setOpt(url);
    handle.setOpt(std::make_unique<curlpp::options::PostFields>(empty_body));
    handle.setOpt(std::make_unique<curlpp::options::PostFieldSize>(
        static_cast<int>(empty_body.length())));

    std::ostringstream response;
    handle.setOpt(std::make_unique<curlpp::options::WriteStream>(&response));
    handle.perform();

    const auto result = IgdbParser().ParseOAuthResponse(response.str());
    if (!result.ok()) {
      return result.status();
    }

    oauth_token_ = *result;
    return absl::OkStatus();
  } catch (std::exception& e) {
    LOG(ERROR) << "Failed to reach remote endpoint: " << e.what();
  }
  return absl::InternalError("Failed to reach Twitch OAuth server.");
}

namespace {
constexpr char kIgdbUrl[] = "https://api.igdb.com/v4";
constexpr char kGamesEndpoint[] = "games.pb";
constexpr char kCoversEndpoint[] = "covers.pb";
constexpr char kFranchisesEndpoint[] = "franchises.pb";
constexpr char kCollectionsEndpoint[] = "collections.pb";

absl::StatusOr<std::string> IgdbPost(const std::string& endpoint,
                                     const std::string& body,
                                     const std::string& client_id,
                                     const std::string& oauth_token) {
  if (oauth_token.empty()) {
    return absl::FailedPreconditionError(
        "Need to call IgdbService::Authenticate() successfully before using "
        "the service.");
  }

  const auto url_string = absl::StrCat(kIgdbUrl, "/", endpoint, "/");
  const auto url = curlpp::options::Url(url_string);

  const std::list<std::string> header = {
      absl::StrCat("Client-ID: ", client_id),
      absl::StrCat("Authorization: ", "Bearer ", oauth_token),
  };

  try {
    curlpp::Easy handle;
    handle.setOpt(url);
    handle.setOpt(std::make_unique<curlpp::options::HttpHeader>(header));
    handle.setOpt(std::make_unique<curlpp::options::PostFields>(body));
    handle.setOpt(std::make_unique<curlpp::options::PostFieldSize>(
        static_cast<int>(body.length())));

    std::ostringstream response;
    handle.setOpt(std::make_unique<curlpp::options::WriteStream>(&response));
    handle.perform();
    return response.str();
  } catch (std::exception& e) {
    return absl::InternalError(
        absl::StrCat("Failed to reach IGDB endpoint.\n", e.what()));
  }
}
}  // namespace

absl::StatusOr<igdb::GameResult> IgdbService::SearchByTitle(
    std::string_view title) const {
  const std::string query =
      absl::StrCat("search \"", std::string(title), "\"; fields *;");

  auto response = IgdbPost(kGamesEndpoint, query, client_id_, oauth_token_);
  if (!response.ok()) {
    return response.status();
  }

  igdb::GameResult game_result;
  if (!game_result.ParseFromString(*response)) {
    return absl::InvalidArgumentError(absl::StrCat(
        "Failed to parse igdb.GameResult for '", std::string(title), "'"));
  }
  return game_result;
}

absl::StatusOr<igdb::Cover> IgdbService::GetCover(int64_t cover_id) const {
  const std::string query =
      absl::StrCat("fields image_id; where id = ", cover_id, ";");
  DLOG(INFO) << "Query on covers: " << query;

  auto response = IgdbPost(kCoversEndpoint, query, client_id_, oauth_token_);
  if (!response.ok()) {
    return response.status();
  }

  igdb::CoverResult cover_result;
  if (!cover_result.ParseFromString(*response)) {
    return absl::InvalidArgumentError(
        absl::StrCat("Failed to parse igdb.CoverResult for '", cover_id, "'"));
  }
  if (cover_result.covers().empty()) {
    absl::NotFoundError(absl::StrCat("cover id: ", cover_id));
  }
  return cover_result.covers(0);
}

absl::StatusOr<igdb::FranchiseResult> IgdbService::GetFranchises(
    const std::vector<int64_t>& franchise_ids) const {
  const std::string query =
      absl::StrCat("fields id, name, url; where id = (",
                   absl::StrJoin(franchise_ids, ","), ");");
  DLOG(INFO) << "Query on franchise: " << query;

  auto response =
      IgdbPost(kFranchisesEndpoint, query, client_id_, oauth_token_);
  if (!response.ok()) {
    return response.status();
  }

  igdb::FranchiseResult franchise_result;
  if (!franchise_result.ParseFromString(*response)) {
    return absl::InvalidArgumentError(
        absl::StrCat("Failed to parse igdb.FranchiseResult for '",
                     absl::StrJoin(franchise_ids, ","), "'"));
  }
  return franchise_result;
}

absl::StatusOr<igdb::Collection> IgdbService::GetCollection(
    int64_t collection_id) const {
  const std::string query =
      absl::StrCat("fields id, name, url; where id = ", collection_id, ";");
  DLOG(INFO) << "Query on collections: " << query;

  auto response =
      IgdbPost(kCollectionsEndpoint, query, client_id_, oauth_token_);
  if (!response.ok()) {
    return response.status();
  }

  igdb::CollectionResult collection_result;
  if (!collection_result.ParseFromString(*response)) {
    return absl::InvalidArgumentError(absl::StrCat(
        "Failed to parse igdb.CollectionResult for '", collection_id, "'"));
  }
  if (collection_result.collections().empty()) {
    absl::NotFoundError(absl::StrCat("collection id: ", collection_id));
  }
  return collection_result.collections(0);
}

}  // namespace espy
