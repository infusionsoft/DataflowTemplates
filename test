#!/usr/bin/env bash

([[ $(type -t cp) == "alias" ]] && unalias cp && CP_ALIASED=true ) || echo "cp is not aliased"









# ateasasfasfasf

if [[ ${CP_ALIASED} ]]; then
  alias cp "cp -i"
  echo "alias on cp restored"
fi
