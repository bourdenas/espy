fn main() {
    prost_build::compile_protos(
        &[
            "../server/proto/igdbapi.proto",
            "../server/proto/library.proto",
            "../server/proto/reconciliation_task.proto",
            "../server/proto/steam_entry.proto",
        ],
        &["../server/proto/"],
    )
    .unwrap();
}
