#!/usr/bin/env bash
set -e

darwin-rebuild build --flake .#xxx
darwin-rebuild switch --flake .#xxx
