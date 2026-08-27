# Build stage
FROM alpine:3.20 AS builder

RUN apk add --no-cache curl xz tar

# Install Zig 0.15.0
RUN curl -fsSL https://ziglang.org/download/0.15.0/zig-linux-x86_64-0.15.0.tar.xz | tar -xJ -C /opt && \
    ln -s /opt/zig-linux-x86_64-0.15.0/zig /usr/local/bin/zig

WORKDIR /build
COPY . .

RUN zig build -Doptimize=ReleaseFast

# Runtime stage
FROM alpine:3.20

WORKDIR /app
COPY --from=builder /build/zig-out/bin/zyphor /usr/local/bin/zyphor

ENTRYPOINT ["/usr/local/bin/zyphor"]

