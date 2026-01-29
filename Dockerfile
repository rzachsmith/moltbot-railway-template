# Build moltbot from source to avoid npm packaging gaps (some dist files are not shipped).
FROM node:22-bookworm AS moltbot-build

# Dependencies needed for moltbot build
RUN apt-get update \
  && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    git \
    ca-certificates \
    curl \
    python3 \
    make \
    g++ \
  && rm -rf /var/lib/apt/lists/*

# Install Bun (moltbot build uses it)
RUN curl -fsSL https://bun.sh/install | bash
ENV PATH="/root/.bun/bin:${PATH}"

RUN corepack enable

WORKDIR /moltbot

# Pin to a known ref (tag/branch). If it doesn't exist, fall back to main.
ARG MOLTBOT_GIT_REF=v2026.1.24
RUN git clone --depth 1 --branch "${MOLTBOT_GIT_REF}" https://github.com/moltbot/moltbot.git .

# Patch: relax version requirements for packages that may reference unpublished versions.
# Apply to all extension package.json files to handle workspace protocol (workspace:*).
RUN set -eux; \
  find ./extensions -name 'package.json' -type f | while read -r f; do \
    sed -i -E 's/"moltbot"[[:space:]]*:[[:space:]]*">=[^"]+"/"moltbot": "*"/g' "$f"; \
    sed -i -E 's/"moltbot"[[:space:]]*:[[:space:]]*"workspace:[^"]+"/"moltbot": "*"/g' "$f"; \
    sed -i -E 's/"clawdbot"[[:space:]]*:[[:space:]]*">=[^"]+"/"clawdbot": "*"/g' "$f"; \
    sed -i -E 's/"clawdbot"[[:space:]]*:[[:space:]]*"workspace:[^"]+"/"clawdbot": "*"/g' "$f"; \
  done

RUN pnpm install --no-frozen-lockfile
RUN pnpm build
ENV CLAWDBOT_PREFER_PNPM=1
RUN pnpm ui:install && pnpm ui:build


# Runtime image
FROM node:22-bookworm
ENV NODE_ENV=production

RUN apt-get update \
  && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    ca-certificates \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Wrapper deps
COPY package.json ./
RUN npm install --omit=dev && npm cache clean --force

# Copy built moltbot
COPY --from=moltbot-build /moltbot /moltbot

# Provide a moltbot executable (entry point is dist/index.js for moltbot)
RUN printf '%s\n' '#!/usr/bin/env bash' 'exec node /moltbot/dist/index.js "$@"' > /usr/local/bin/moltbot \
  && chmod +x /usr/local/bin/moltbot

# Backwards compatibility: clawdbot shim points to moltbot
RUN ln -s /usr/local/bin/moltbot /usr/local/bin/clawdbot

COPY src ./src

# The wrapper listens on this port.
ENV MOLTBOT_PUBLIC_PORT=8080
ENV PORT=8080
EXPOSE 8080
CMD ["node", "src/server.js"]
