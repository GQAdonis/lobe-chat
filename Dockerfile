FROM node:20-slim AS base

## Sharp dependencies, copy all the files for production
FROM base AS sharp
ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"
RUN corepack enable

WORKDIR /app

RUN pnpm add sharp

## Install dependencies only when needed
FROM base AS builder
ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"
RUN corepack enable

WORKDIR /app

COPY package.json ./

# If you want to build docker in China
# RUN npm config set registry https://registry.npmmirror.com/
RUN pnpm i

COPY . .
RUN pnpm run build:docker # run build standalone for docker version

## Production image, copy all the files and run next
FROM base AS runner
WORKDIR /app

ENV NODE_ENV production

RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs

COPY --from=builder /app/public ./public

# Set the correct permission for prerender cache
RUN mkdir .next
RUN chown nextjs:nodejs .next

# Automatically leverage output traces to reduce image size
# https://nextjs.org/docs/advanced-features/output-file-tracing
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static
COPY --from=sharp --chown=nextjs:nodejs /app/node_modules/.pnpm ./node_modules/.pnpm

USER nextjs

EXPOSE 3210

# set hostname to localhost
ENV HOSTNAME "0.0.0.0"
ENV PORT=3210

# General Variables
ENV ACCESS_CODE ""

ENV API_KEY_SELECT_MODE ""

# OpenAI
ENV OPENAI_API_KEY "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"
ENV OPENAI_PROXY_URL ""
ENV OPENAI_MODEL_LIST ""

# Azure OpenAI
ENV USE_AZURE_OPENAI ""
ENV AZURE_API_KEY ""
ENV AZURE_API_VERSION ""

# Google
ENV GOOGLE_API_KEY ""

# Zhipu
ENV ZHIPU_API_KEY ""

# Moonshot
ENV MOONSHOT_API_KEY ""

# Ollama
ENV OLLAMA_PROXY_URL ""
ENV OLLAMA_MODEL_LIST ""

# Perplexity
ENV PERPLEXITY_API_KEY "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"

# Anthropic
ENV ANTHROPIC_API_KEY "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"

# Mistral
ENV MISTRAL_API_KEY "N3203gM7sX6sUBqdHYSjnF0Y3al82lT8"

# OpenRouter
ENV OPENROUTER_API_KEY ""
ENV OPENROUTER_MODEL_LIST ""

# 01.AI
ENV ZEROONE_API_KEY ""

# TogetherAI
ENV TOGETHERAI_API_KEY "c37d9a06808984d59070cc46d97b56382d13e5ecd076732f90b8a91ce9ddbdad"

CMD ["node", "server.js"]
