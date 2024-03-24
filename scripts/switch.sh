#!/usr/bin/env bash
set -e

nix flake update
darwin-rebuild build --flake .#xxx
darwin-rebuild switch --flake .#xxx
