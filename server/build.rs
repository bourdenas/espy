fn main() {
    prost_build::compile_protos(
        &[
            "proto/igdbapi.proto",
            "proto/library.proto",
            "proto/steam_entry.proto",
        ],
        &["proto/"],
    )
    .unwrap();
}
