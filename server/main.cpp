#include <algorithm>
#include <execution>
#include <filesystem>
#include <fstream>
#include <future>

#include <absl/flags/flag.h>
#include <absl/flags/parse.h>
#include <absl/strings/str_cat.h>
#include <absl/strings/str_join.h>
#include <glog/logging.h>
#include <curlpp/cURLpp.hpp>

#include "igdb/igdb_service.hpp"
#include "json/key_parser.hpp"
#include "proto/igdbapi.pb.h"
#include "proto/library.pb.h"
#include "proto/reconciliation_task.pb.h"
#include "steam/steam_library.hpp"
#include "steam/steam_service.hpp"
#include "util/proto_util.hpp"

ABSL_FLAG(std::string, key_store, "../keys.json",
          "Path to JSON file containing application keys.");
ABSL_FLAG(std::string, search, "", "Search a title in IGDB.");

constexpr char kTestUser[] = "testing";

namespace {
void RetrieveTitle(std::string_view title, const espy::KeyParser& keys) {
  auto promise = std::async(
      std::launch::async,
      [&keys](std::string_view title) {
        auto igdb =
            espy::IgdbService(keys.igdb_client_id(), keys.igdb_secret());
        if (auto status = igdb.Authenticate(); !status.ok()) {
          LOG(ERROR) << "Failed to authenticate with IGDB: " << status;
        };
        return igdb.SearchByTitle(title);
      },
      title);

  auto igdb_response = promise.get();
  if (!igdb_response.ok()) {
    LOG(ERROR) << igdb_response.status();
    return;
  }
  for (const auto& game : igdb_response->games()) {
    LOG(INFO) << game.name();
  }
}

constexpr char kHtmlCode[] = R"(
<html>
<head>
  <style>
    .app {
      display: grid;
      grid-gap: 15px;
      overflow: hidden;
      grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
      grid-auto-flow: dense;
    }
  </style>
</head>

<body>
  <div class="app">
)";

constexpr char kHtmlTail[] = R"(
  </div>
</body>
</html>
)";

void RenderHtml(const espy::Library& library) {
  std::vector<std::string> html_items(library.entry().size());
  std::transform(library.entry().begin(), library.entry().end(),
                 html_items.begin(),
                 [](const espy::GameEntry& entry) {
                   return absl::StrCat(
                       "<div class=\"item\"><figure><p><img "
                       "src=\"https://images.igdb.com/igdb/image/upload/t_cover_big/",
                       entry.game().cover().image_id(), ".jpg\"><figcaption><a href=\"",
                       entry.game().url(), "\">", entry.game().name(),
                       "</a></figcaption></figure></div>");
                 });

  std::ofstream html_file;
  html_file.open("library.html");
  html_file << kHtmlCode
            << absl::StrJoin(html_items.begin(), html_items.end(), "\n")
            << kHtmlTail;
  html_file.close();
}
}  // namespace

int main(int argc, char* argv[]) {
  GOOGLE_PROTOBUF_VERIFY_VERSION;
  absl::ParseCommandLine(argc, argv);

  curlpp::Cleanup cleaner;

  espy::KeyParser keys;
  auto status = keys.ParseKeyFile(absl::GetFlag(FLAGS_key_store));
  if (!status.ok()) {
    LOG(ERROR) << status;
    return 0;
  }

  if (!absl::GetFlag(FLAGS_search).empty()) {
    LOG(INFO) << "Searching for '" << absl::GetFlag(FLAGS_search) << "'...";
    RetrieveTitle(absl::GetFlag(FLAGS_search), keys);
    return 0;
  }

  espy::IgdbService igdb_service(keys.igdb_client_id(), keys.igdb_secret());
  if (!igdb_service.Authenticate().ok()) {
    LOG(ERROR) << "IGDB authentication failed.";
    return 0;
  }

  espy::ReconciliationService reconciler(&igdb_service);
  espy::SteamService steam_service(keys.steam_espy_key(), keys.steam_user_id());
  auto result =
      espy::SteamLibrary::Create(kTestUser, &steam_service, &reconciler);

  if (!result.ok()) {
    LOG(ERROR) << result.status();
    return 0;
  }
  auto steam_library = std::move(*result);

  status = steam_library.Sync();
  if (!status.ok()) {
    LOG(ERROR) << status;
    return 0;
  }

  RenderHtml(steam_library.games());

  return 0;
}
