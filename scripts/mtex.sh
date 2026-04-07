#!/usr/bin/env bash

# This script manages the mtex submodule.
# Usage:
# ./scripts/mtex.sh checkout <REV>
# <REV> can be:
# - commit hash
# - tag
# - branch name
#
# If <REV> is a branch, the submodule will track that branch in .gitmodules.
# If <REV> is a commit or tag, the submodule is left in detached HEAD state.

set -euo pipefail

MTEX_FOLDER="src/pynxtools_microstructure/mtex"

update_mtex_version() {
  cd "$MTEX_FOLDER" && echo "updating mtex-version.txt"
  printf "$(git describe --always --dirty --tags --long --abbrev=8 --match '*[0-9]*')" > ../mtex-version.txt
  cd ../../../
}

get_default_branch() {
  git -C "$MTEX_FOLDER" remote show origin | awk '/HEAD branch/ {print $NF}'
}

checkout_definitions() {
  local ref="$1"

  echo "checking out definitions submodule at: $ref"

  git submodule update --init "$MTEX_FOLDER"
  git -C "$MTEX_FOLDER" fetch --tags origin

  git -C "$MTEX_FOLDER" checkout "$ref"

  # Check whether we are on a branch or detached HEAD
  local current_branch
  current_branch="$(git -C "$MTEX_FOLDER" branch --show-current)"

  if [[ -n "$current_branch" ]]; then
    echo "detected branch checkout: $current_branch"

    local default_branch
    default_branch="$(get_default_branch)"

    if [[ "$current_branch" == "$default_branch" ]]; then
      echo "removing submodule branch setting from .gitmodules (default branch)"
      git config -f .gitmodules --unset \
        submodule.$MTEX_FOLDER.branch || true
    else
      echo "setting submodule to track branch: $current_branch"
      git config -f .gitmodules \
        submodule.$MTEX_FOLDER.branch "$current_branch"
    fi
  else
    echo "detected detached checkout (commit or tag)"
    git config -f .gitmodules --unset \
      submodule.$MTEX_FOLDER.branch || true
  fi

  git submodule sync "$MTEX_FOLDER"
}

print_usage() {
echo "Usage:"
echo "  $0 checkout <REV>"
exit 1
}

main() {
if [[ $# -lt 1 ]]; then
print_usage
fi

project_dir=$(dirname "$(dirname "$(realpath "$0")")")
cd "$project_dir"

case "$1" in
checkout)
[[ $# -eq 2 ]] || print_usage
checkout_definitions "$2"
;;
*)
echo "Error: Unknown command '$1'"
print_usage
;;
esac

update_mtex_version
}

main "$@"
