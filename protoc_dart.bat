protoc --proto_path=../server/proto/ --plugin=protoc-gen-dart=%USERPROFILE%\AppData\Local\Pub\Cache\bin\protoc-gen-dart.bat --dart_out=grpc:../client/lib/proto ../server/proto\*.proto
