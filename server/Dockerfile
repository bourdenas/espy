FROM rust as builder

RUN USER=root cargo new --bin espy_server
WORKDIR /espy_server

COPY . .

RUN cargo build --release --bin http_server

FROM debian:buster-slim

RUN apt-get update && apt-get install -y libssl1.1 ca-certificates && rm -rf /var/lib/apt/lists/*
COPY --from=builder /espy_server/target/release/http_server /usr/local/bin/http_server
COPY ./keys.json ./keys.json
COPY ./espy-library-firebase-adminsdk-sncpo-3da8ca7f57.json ./espy-library-firebase-adminsdk-sncpo-3da8ca7f57.json

EXPOSE 3030

CMD ["http_server"]
