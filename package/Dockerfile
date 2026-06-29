# Kyto compiler container — ships the kura CLI (Linux x86-64).
# Build context must include bin/kura-asm at package/kura-asm (CI copies it here).

FROM debian:bookworm-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates \
    && rm -rf /var/lib/apt/lists/*

COPY kura-asm /usr/local/bin/kura
RUN chmod +x /usr/local/bin/kura

WORKDIR /work
ENTRYPOINT ["kura"]
CMD ["--version"]
