#ifndef ESPY_SERVER_IGDB_RECONCILIATION_SERVICE_HPP_
#define ESPY_SERVER_IGDB_RECONCILIATION_SERVICE_HPP_

#include <vector>

#include <absl/status/statusor.h>

#include "igdb/igdb_service.hpp"
#include "proto/library.pb.h"
#include "proto/reconciliation_task.pb.h"
#include "proto/steam_entry.pb.h"

namespace espy {

// Reconciles game entries from different platforms to a uniquely identifiable
// IGDB entry.
class ReconciliationService {
 public:
  ReconciliationService(IgdbService* igdb_service)
      : igdb_service_(igdb_service) {}
  virtual ~ReconciliationService() {}

  // Reconcile steam game entries and separate successfully reconciled
  // entries from those failed.
  virtual absl::StatusOr<Library> Reconcile(
      std::vector<SteamEntry> entries) const;

 private:
  IgdbService* igdb_service_;
};

}  // namespace espy

#endif  // ESPY_SERVER_IGDB_RECONCILIATION_SERVICE_HPP_
