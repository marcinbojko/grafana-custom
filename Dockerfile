ARG GRAFANA_VERSION="8.5.2"
FROM grafana/grafana:${GRAFANA_VERSION}
USER root
ARG GF_INSTALL_IMAGE_RENDERER_PLUGIN="true"
ARG GF_INSTALL_PLUGINS="true"
ENV GF_PATHS_PLUGINS="/var/lib/grafana-plugins"
LABEL version="8.5.2.20220504"
LABEL release="grafana-custom"
LABEL maintainer="marcinbojko"
SHELL ["/bin/ash", "-euo", "pipefail", "-c"]
HEALTHCHECK --interval=30s --timeout=15s --retries=3 CMD [ "curl","localhost:3000/healthz" ]
RUN mkdir -p "$GF_PATHS_PLUGINS" \
    && chown -R 472:472 "$GF_PATHS_PLUGINS" \
    && apk add --no-cache curl jq \
    && rm -rf /tmp/*

RUN if [ $GF_INSTALL_IMAGE_RENDERER_PLUGIN = "true" ]; then \
    echo "http://dl-cdn.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories && \
    echo "http://dl-cdn.alpinelinux.org/alpine/edge/main" >> /etc/apk/repositories && \
    echo "http://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories && \
    #apk --no-cache  upgrade && \
    apk add --no-cache udev ttf-opensans chromium && \
    rm -rf /tmp/* && \
    rm -rf /usr/share/grafana/tools/phantomjs; \
fi
USER grafana
ENV GF_RENDERER_PLUGIN_CHROME_BIN="/usr/bin/chromium-browser"
RUN if [ "$GF_INSTALL_IMAGE_RENDERER_PLUGIN" = "true" ]; then \
    grafana-cli \
        --pluginsDir "$GF_PATHS_PLUGINS" \
        --pluginUrl https://github.com/grafana/grafana-image-renderer/releases/latest/download/plugin-linux-x64-glibc-no-chromium.zip \
        plugins install grafana-image-renderer; \
fi
# shellcheck SC2026
RUN if [ "$GF_INSTALL_PLUGINS" = "true" ]; then \
    PLUGINS=$(curl -s https://grafana.net/api/plugins?orderBy=name | jq '.items[] | select(.internal=='false') | .slug' | tr -d '"'); \
    for plugin in $PLUGINS; do \
        grafana-cli --pluginsDir "$GF_PATHS_PLUGINS" plugins install ${plugin} && true; \
    done; \
fi
