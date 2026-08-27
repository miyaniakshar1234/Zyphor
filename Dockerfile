# Build stage
FROM ubuntu:24.04 AS builder

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl xz-utils ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Install Zig 0.15.2 (matches local dev version exactly)
RUN curl -fsSL https://ziglang.org/download/0.15.2/zig-x86_64-linux-0.15.2.tar.xz | tar -xJ -C /opt && \
    ln -s /opt/zig-x86_64-linux-0.15.2/zig /usr/local/bin/zig

WORKDIR /build
COPY . .

RUN zig build -Doptimize=ReleaseFast

# Runtime stage
FROM ubuntu:24.04

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY --from=builder /build/zig-out/bin/zyphor /usr/local/bin/zyphor

ENTRYPOINT ["/usr/local/bin/zyphor"]
