#!/bin/bash

if [[ -v SSH_KEY ]]; then
  echo "${SSH_KEY}" > $HOME/.ssh/id_rsa
  ssh-keyscan github.com >> ~/.ssh/known_hosts
fi

exec "$@"
