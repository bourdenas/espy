#include "json/json_util.hpp"

#include <absl/strings/str_cat.h>
#include <nlohmann/json.hpp>

namespace espy {
namespace json {

absl::StatusOr<nlohmann::json> GetObject(const nlohmann::json& obj,
                                         std::string_view field_name) {
  const auto it = obj.find(field_name);
  if (it == obj.end() || !it->is_object()) {
    return absl::NotFoundError(
        absl::StrCat("JSON text has no '", std::string(field_name),
                     "' field or its type is not Object."));
  }
  return it->get<nlohmann::json>();
}

absl::StatusOr<std::string> GetString(const nlohmann::json& obj,
                                      std::string_view field_name) {
  const auto it = obj.find(field_name);
  if (it == obj.end() || !it->is_string()) {
    return absl::NotFoundError(
        absl::StrCat("JSON text has no '", std::string(field_name),
                     "' field or its type is not String."));
  }
  return it->get<std::string>();
}

absl::StatusOr<int> GetInt(const nlohmann::json& obj,
                           std::string_view field_name) {
  const auto it = obj.find(field_name);
  if (it == obj.end() || !it->is_number_integer()) {
    return absl::NotFoundError(
        absl::StrCat("Response has no '", std::string(field_name),
                     "' field or its type is not Integer."));
  }
  return it->get<int>();
}

}  // namespace json
}  // namespace espy
