#include "json/key_parser.hpp"

#include <fstream>

#include <absl/strings/str_cat.h>
#include <nlohmann/json.hpp>
#include <glog/logging.h>

#include "json/json_util.hpp"

namespace espy {

absl::Status KeyParser::ParseKeyFile(const std::string& path) {
  std::ifstream json_file(path);
  auto json_obj = nlohmann::json::parse(json_file, nullptr, false);
  if (json_obj.is_discarded()) {
    return absl::InvalidArgumentError(absl::StrCat(
        "Failed to parse JSON keys or file '", path, "' was not found."));
  }

  auto igdb = json::GetObject(json_obj, "igdb");
  if (!igdb.ok()) {
    return igdb.status();
  }
  auto client_id = json::GetString(*igdb, "client_id");
  if (!client_id.ok()) {
    return client_id.status();
  }
  igdb_client_id_ = *client_id;

  auto secret = json::GetString(*igdb, "secret");
  if (!secret.ok()) {
    return secret.status();
  }
  igdb_secret_ = *secret;

  auto steam = json::GetObject(json_obj, "steam");
  if (!steam.ok()) {
    return steam.status();
  }
  auto client_key = json::GetString(*steam, "client_key");
  if (!client_key.ok()) {
    return client_key.status();
  }
  steam_espy_key_ = *client_key;
  auto user_id = json::GetString(*steam, "user_id");
  if (!user_id.ok()) {
    return user_id.status();
  }
  steam_user_id_ = *user_id;

  return absl::OkStatus();
}

}  // namespace espy
