FROM mcr.microsoft.com/devcontainers/base:ubuntu

RUN apt-get update \
  && apt-get install -y --no-install-recommends stow \
  && mkdir -p /opt/test-stow \
  && cp "$(command -v stow)" /opt/test-stow/stow \
  && rm -f "$(command -v stow)" \
  && mv /usr/bin/apt-get /usr/bin/apt-get.real \
  && mv /usr/bin/apt /usr/bin/apt.real \
  && rm -rf /var/lib/apt/lists/*

COPY tests/support/fake-package-manager.sh /usr/local/bin/fake-package-manager
RUN chmod +x /usr/local/bin/fake-package-manager \
  && ln -sf /usr/local/bin/fake-package-manager /usr/local/bin/pacman
