# Dockerfile
# Building for production

FROM elixir:1.11-alpine as build

RUN mkdir -p /opt/app

COPY . /opt/app
WORKDIR /opt/app

ENV MIX_ENV=prod

RUN apk --no-cache --update add \
  cargo \
  g++ \
  gcc \
  git \
  libc-dev \
  make \
  nodejs \
  nodejs-npm \
  python3 \
  rust

RUN cd /opt/app && \
  mix local.hex --force && \
  mix local.rebar --force && \
  mix deps.get

RUN npm install npm -g --no-progress && \
  cd /opt/app/assets && \
  npm ci && \
  NODE_ENV=production npm run build

RUN mix phx.digest
RUN mix release

# Dockerfile
# Runing in production

FROM elixir:1.11-alpine as release

RUN apk add --no-cache bash openssl

RUN mkdir -p /opt/app

COPY --from=build /opt/app/_build/prod/rel/appcenter_dashboard /opt/app

WORKDIR /opt/app

EXPOSE 4000

ENTRYPOINT ["/opt/app/bin/appcenter_dashboard"]
CMD ["start"]
