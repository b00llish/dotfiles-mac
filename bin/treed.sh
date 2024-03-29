#!/usr/bin/env bash

# Copyright (C) 2016-present Arctic Ice Studio <development@arcticicestudio.com>
# Copyright (C) 2016-present Sven Greb <development@svengreb.de>

# Project:    igloo
# Repository: https://github.com/arcticicestudio/igloo
# License:    MIT

# Prints an advanced numbered, recursive and colored directory treeview.
#
# @param $@ the directory path(s)

treed() {
  if command -v tree > /dev/null 2>&1; then
    tree -aC -I ".git|node_modules|bower_components" --dirsfirst "$@" | less -FRNX
  fi
}

treed $@