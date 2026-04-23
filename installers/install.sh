#!/usr/bin/env bash
#
# Run every */install.sh under the dotfiles tree (e.g. py/install.sh).
# Excludes itself to avoid infinite recursion.

set -e

cd "$(dirname "$0")"/..

find . -name install.sh -not -path './installers/*' | while read installer; do
  echo "==> running $installer"
  sh -c "$installer"
done