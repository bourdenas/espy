#ifndef ESPY_SERVER_JSON_KEY_PARSER_HPP_
#define ESPY_SERVER_JSON_KEY_PARSER_HPP_

#include <string>

#include <absl/status/status.h>

namespace espy {

class KeyParser {
 public:
  absl::Status ParseKeyFile(const std::string& path);

  const std::string& igdb_client_id() const { return igdb_client_id_; }
  const std::string& igdb_secret() const { return igdb_secret_; }
  const std::string& steam_espy_key() const { return steam_espy_key_; }
  const std::string& steam_user_id() const { return steam_user_id_; }

 private:
  std::string igdb_client_id_;
  std::string igdb_secret_;
  std::string steam_espy_key_;
  std::string steam_user_id_;
};

}  // namespace espy

#endif  // ESPY_SERVER_JSON_ΚΕΥ_PARSER_HPP_
