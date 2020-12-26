#ifndef ESPY_SERVER_IGDB_IGDB_SERVICE_HPP_
#define ESPY_SERVER_IGDB_IGDB_SERVICE_HPP_

#include <string>
#include <string_view>

#include <absl/status/statusor.h>

#include "proto/game_entry.pb.h"
#include "proto/search_result.pb.h"

namespace espy {

class IgdbService {
 public:
  IgdbService(std::string client_id, std::string secret)
      : client_id_(std::move(client_id)), secret_(secret) {}
  virtual ~IgdbService() = default;

  // Need to Authenticate to the service before doing any other operation.
  // Returns a status error if authentication failed.
  absl::Status Authenticate();

  // Returns search result candidates from IGDB server with entries that
  // match input title.
  virtual absl::StatusOr<igdb::SearchResultList> SearchByTitle(
      std::string_view title) const;

  // Returns game cover hash for constructing image URL from a cover id in
  // IGDB's cover endpoint.
  virtual absl::StatusOr<std::string> GetCover(int64_t cover_id) const;

  virtual absl::StatusOr<std::vector<Franchise>> GetFranchises(
      const std::vector<int64_t>& franchise_ids) const;

  virtual absl::StatusOr<Franchise> GetSeries(int64_t collection_id) const;

 private:
  const std::string client_id_;
  const std::string secret_;

  std::string oauth_token_;
};

}  // namespace espy

#endif  // ESPY_SERVER_IGDB_IGDB_SERVICE_HPP_
