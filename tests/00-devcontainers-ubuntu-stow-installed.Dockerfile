FROM mcr.microsoft.com/devcontainers/base:ubuntu

RUN apt-get update \
  && apt-get install -y --no-install-recommends stow \
  && rm -rf /var/lib/apt/lists/*
