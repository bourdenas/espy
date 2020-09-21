#include "igdb/igdb_service.hpp"

#include <memory>
#include <sstream>

#include <absl/strings/str_cat.h>
#include <curlpp/cURLpp.hpp>
#include <curlpp/Easy.hpp>
#include <curlpp/Options.hpp>
#include <glog/logging.h>

namespace espy {

constexpr char kIgdbHostname[] = "https://api-v3.igdb.com";
constexpr char kGamesEndpoint[] = "/games/";

std::string IgdbService::SearchGame(std::string_view title) const {
  const auto host = kIgdbHostname;
  const auto target = kGamesEndpoint;

  const auto url = curlpp::options::Url(absl::StrCat(host, target));
  LOG(INFO) << absl::StrCat(host, target);

  const std::list<std::string> header = {
      absl::StrCat("user-key: ", key_),
  };
  const std::string body =
      absl::StrCat("search \"", std::string(title),
                   "\"; fields name; where platforms = (6);");

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
}

}  // namespace espy
