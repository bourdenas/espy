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

namespace {
constexpr char kTwitchOAuthUrl[] = "https://id.twitch.tv/oauth2/token?";

// Returns OAuth token for Twitch API service.
absl::StatusOr<std::string> Authenticate(std::string client_id,
                                         std::string secret) {
  const std::string params =
      absl::StrJoin({absl::StrCat("client_id=", client_id),
                     absl::StrCat("client_secret=", secret),
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

    return IgdbParser().ParseOAuthResponse(response.str());
  } catch (std::exception& e) {
    LOG(ERROR) << "Failed to reach remote endpoint: " << e.what();
  }
  return absl::InternalError("Failed to reach Twitch OAuth server.");
}
}  // namespace

constexpr char kIgdbUrl[] = "https://api.igdb.com/v4";
constexpr char kGamesEndpoint[] = "games";

absl::StatusOr<igdb::SearchResultList> IgdbService::SearchByTitle(
    std::string_view title) const {
  if (oauth_token_.empty()) {
    const auto result = Authenticate(client_id_, secret_);
    if (!result.ok()) {
      return result.status();
    }
    oauth_token_ = *result;
  }

  const auto host = kIgdbUrl;
  const auto target = kGamesEndpoint;

  const auto url_string = absl::StrCat(host, "/", target, "/");
  const auto url = curlpp::options::Url(url_string);

  const std::list<std::string> header = {
      absl::StrCat("Client-ID: ", client_id_),
      absl::StrCat("Authorization: ", "Bearer ", oauth_token_),
  };
  const std::string body =
      absl::StrCat("search \"", std::string(title), "\"; fields name;");

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

    return IgdbParser().ParseSearchByTitleResponse(response.str());
  } catch (std::exception& e) {
    LOG(ERROR) << "Failed to reach remote endpoint: " << e.what();
  }
  return absl::InternalError("Failed to reach IGDB.");
}

}  // namespace espy
