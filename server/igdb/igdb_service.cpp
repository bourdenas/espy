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
absl::StatusOr<std::string> Post(const std::string& host,
                                 const std::string& endpoint,
                                 const std::string& body,
                                 const std::string& client_id,
                                 const std::string& oauth_token) {
  if (oauth_token.empty()) {
    return absl::FailedPreconditionError(
        "Need to call IgdbService::Authenticate() successfully before using "
        "the service.");
  }

  const auto url_string = absl::StrCat(host, "/", endpoint, "/");
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

constexpr char kIgdbUrl[] = "https://api.igdb.com/v4";
constexpr char kGamesEndpoint[] = "games";
constexpr char kCoversEndpoint[] = "covers";
constexpr char kFranchisesEndpoint[] = "franchises";
constexpr char kCollectionsEndpoint[] = "collections";
}  // namespace

absl::StatusOr<igdb::SearchResultList> IgdbService::SearchByTitle(
    std::string_view title) const {
  const std::string query =
      absl::StrCat("search \"", std::string(title), "\"; fields *;");

  auto result = Post(kIgdbUrl, kGamesEndpoint, query, client_id_, oauth_token_);
  return result.ok() ? IgdbParser().ParseSearchByTitleResponse(*result)
                     : result.status();
}

absl::StatusOr<std::string> IgdbService::GetCover(int64_t cover_id) const {
  const std::string query =
      absl::StrCat("fields image_id; where id = ", cover_id, ";");
  DLOG(INFO) << "Query on covers: " << query;

  auto result =
      Post(kIgdbUrl, kCoversEndpoint, query, client_id_, oauth_token_);
  return result.ok() ? IgdbParser().ParseGetCoverResponse(*result)
                     : result.status();
}

absl::StatusOr<std::vector<Franchise>> IgdbService::GetFranchises(
    const std::vector<int64_t>& franchise_ids) const {
  const std::string query =
      absl::StrCat("fields id, name, url; where id = (",
                   absl::StrJoin(franchise_ids, ","), ");");
  DLOG(INFO) << "Query on franchise: " << query;

  auto result =
      Post(kIgdbUrl, kFranchisesEndpoint, query, client_id_, oauth_token_);
  return result.ok() ? IgdbParser().ParseGetFranchiseResponse(*result)
                     : result.status();
}

absl::StatusOr<Franchise> IgdbService::GetSeries(int64_t collection_id) const {
  const std::string query =
      absl::StrCat("fields id, name, url; where id = ", collection_id, ";");
  DLOG(INFO) << "Query on franchise: " << query;

  auto result =
      Post(kIgdbUrl, kCollectionsEndpoint, query, client_id_, oauth_token_);
  if (!result.ok()) {
    return result.status();
  }

  auto parsed_result = IgdbParser().ParseGetFranchiseResponse(*result);
  if (!parsed_result.ok()) {
    return parsed_result.status();
  }
  return parsed_result->front();
}

}  // namespace espy
