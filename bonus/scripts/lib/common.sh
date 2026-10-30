# shellcheck shell=bash

readonly GREEN=$'\033[0;32m'
readonly YELLOW=$'\033[0;33m'
readonly RED=$'\033[0;31m'
readonly RESET=$'\033[0m'


info()    { echo "$*"; }
success() { echo "${GREEN}$*${RESET}"; }
warn()    { echo "${YELLOW}$*${RESET}" >&2; }
error()   { echo "${RED}$*${RESET}" >&2; }