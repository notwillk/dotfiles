FROM alpine:3.20

RUN apk add --no-cache bash gnupg stow \
  && mkdir -p /opt/test-stow \
  && cp "$(command -v stow)" /opt/test-stow/stow \
  && rm -f "$(command -v stow)"

COPY tests/support/fake-package-manager.sh /usr/local/bin/fake-package-manager
RUN chmod +x /usr/local/bin/fake-package-manager \
  && ln -sf /usr/local/bin/fake-package-manager /usr/local/bin/apk
