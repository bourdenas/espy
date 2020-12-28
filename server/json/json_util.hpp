#ifndef ESPY_SERVER_JSON_JSON_UTIL_HPP_
#define ESPY_SERVER_JSON_JSON_UTIL_HPP_

#include <string>
#include <string_view>

#include <absl/status/statusor.h>
#include <nlohmann/json.hpp>

namespace espy {
namespace json {

absl::StatusOr<nlohmann::json> GetObject(const nlohmann::json& obj,
                                         std::string_view field_name);

absl::StatusOr<std::string> GetString(const nlohmann::json& obj,
                                      std::string_view field_name);

absl::StatusOr<int> GetInt(const nlohmann::json& obj,
                           std::string_view field_name);

}  // namespace json
}  // namespace espy

#endif  // ESPY_SERVER_JSON_JSON_UTIL_HPP_
