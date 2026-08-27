# Build stage
FROM alpine:3.20 AS builder

RUN apk add --no-cache curl jq xz tar

# Install Zig 0.15.x from the official download index
ARG ZIG_VERSION=0.15.0
RUN set -eux; \
    ZIG_TARBALL_URL="$(curl -fsSL https://ziglang.org/download/index.json | jq -r --arg version "$ZIG_VERSION" 'to_entries[] | select(.key | startswith($version)) | .value["x86_64-linux"].tarball' | head -n 1)"; \
    test -n "$ZIG_TARBALL_URL" && test "$ZIG_TARBALL_URL" != "null"; \
    ZIG_DIR="$(basename "$ZIG_TARBALL_URL" .tar.xz)"; \
    curl -fsSL "$ZIG_TARBALL_URL" | tar -xJ -C /opt; \
    ln -s "/opt/$ZIG_DIR/zig" /usr/local/bin/zig

WORKDIR /build
COPY . .

RUN zig build -Doptimize=ReleaseFast

# Runtime stage
FROM alpine:3.20

WORKDIR /app
COPY --from=builder /build/zig-out/bin/zyphor /usr/local/bin/zyphor

ENTRYPOINT ["/usr/local/bin/zyphor"]
