# Stage 1: Install and extract in Alpine
FROM alpine:latest AS builder

RUN apk add --no-cache bash curl libgcc libstdc++ ripgrep unzip tar patchelf

# Install Claude Code
RUN set -e && curl -fsSL https://claude.ai/install.sh | bash

# Create export directory structure
RUN mkdir -p /out/bin /out/lib /out/usr/lib

# Copy Claude binary
RUN cp -L /root/.local/bin/claude /out/bin/claude

# Patch RPATH so the binary finds musl libs relative to itself
RUN patchelf --set-rpath '$ORIGIN/../lib:$ORIGIN/../usr/lib' /out/bin/claude

# Copy runtime dependencies
RUN cp /lib/ld-musl-x86_64.so.1 /out/lib/
RUN cp /usr/lib/libstdc++.so.6* /out/usr/lib/
RUN cp /usr/lib/libgcc_s.so.1* /out/usr/lib/
RUN cp $(which rg) /out/bin/rg

# Generate settings
RUN echo '{ "env": { "USE_BUILTIN_RIPGREP": "0" } }' > /out/settings.json

# Stage 2: Export
FROM scratch
COPY --from=builder /out/ /
