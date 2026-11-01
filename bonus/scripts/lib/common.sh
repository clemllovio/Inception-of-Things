# shellcheck shell=bash

readonly GREEN=$'\033[0;32m'
readonly YELLOW=$'\033[0;33m'
readonly RED=$'\033[0;31m'
readonly CYAN=$'\033[0;36m'
readonly RESET=$'\033[0m'
readonly BOLD=$'\033[1m'

info()    { echo "$*"; }
success() { echo "${GREEN}$*${RESET}"; }
warn()    { echo "${YELLOW}$*${RESET}" >&2; }
error()   { echo "${RED}$*${RESET}" >&2; }
step() { echo; echo "${BOLD}${CYAN}==> $*${RESET}"; }

run_quiet() {
	local output
	output="$("$@" 2>&1)" || { echo "$output" >&2; return 1; }
}