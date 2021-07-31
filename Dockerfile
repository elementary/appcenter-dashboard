# Dockerfile
# Building for production

FROM elixir:1.12-alpine as build

RUN mkdir -p /opt/app

COPY . /opt/app
WORKDIR /opt/app

ENV MIX_ENV=prod

RUN apk --no-cache --update add \
  g++ \
  gcc \
  git \
  libc-dev \
  make \
  nodejs \
  npm

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

FROM elixir:1.12-alpine as release

RUN apk add --no-cache bash git openssh openssl

RUN mkdir -p $HOME/.ssh

RUN touch $HOME/.ssh/id_rsa
RUN touch $HOME/.ssh/known_hosts

RUN chmod 600 $HOME/.ssh/id_rsa

RUN mkdir -p /opt/app

COPY --from=build /opt/app/_build/prod/rel/appcenter_dashboard /opt/app
ADD entrypoint.sh /entrypoint.sh

WORKDIR /opt/app

EXPOSE 4000

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/opt/app/bin/appcenter_dashboard", "start"]
