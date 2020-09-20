#ifndef ESPY_SERVER_IGDB_IGDB_SERVICE_HPP_
#define ESPY_SERVER_IGDB_IGDB_SERVICE_HPP_

#include <string>
#include <string_view>

namespace espy {

class IgdbService {
 public:
  IgdbService(std::string key) : key_(std::move(key)) {}

  // Returns JSON response from IGDB server with entries that match input title.
  std::string SearchGame(std::string_view title) const;

 private:
  std::string key_;
};

}  // namespace espy

#endif  // ESPY_SERVER_IGDB_IGDB_SERVICE_HPP_
