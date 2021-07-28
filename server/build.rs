fn main() -> Result<(), Box<dyn std::error::Error>> {
    // tonic_build::compile_protos() is a bit restrictive; if compiling multiple
    // proto files with same package it overwrites them (using
    // {package_name}.rs) instead producing separate different files.
    //
    // A workaround is to use a root proto file that imports all other and
    // produce one big rs file.
    tonic_build::compile_protos("proto/espy.proto")?;
    Ok(())
}
