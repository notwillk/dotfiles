FROM mcr.microsoft.com/devcontainers/base:ubuntu

RUN mv /usr/bin/apt-get /usr/bin/apt-get.real \
  && mv /usr/bin/apt /usr/bin/apt.real
