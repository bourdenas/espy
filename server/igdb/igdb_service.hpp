#ifndef ESPY_SERVER_IGDB_IGDB_SERVICE_HPP_
#define ESPY_SERVER_IGDB_IGDB_SERVICE_HPP_

#include <string>
#include <string_view>

#include <absl/status/statusor.h>

#include "proto/search_result.pb.h"

namespace espy {

class IgdbService {
 public:
  IgdbService(std::string key) : key_(std::move(key)) {}
  virtual ~IgdbService() = default;

  // Returns search result candidates from IGDB server with entries that
  // match input title.
  virtual absl::StatusOr<igdb::SearchResultList> SearchByTitle(
      std::string_view title) const;

 private:
  std::string key_;
};

}  // namespace espy

#endif  // ESPY_SERVER_IGDB_IGDB_SERVICE_HPP_
