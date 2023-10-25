ARG GRAFANA_VERSION="9.5.12"
FROM grafana/grafana-oss:${GRAFANA_VERSION}
USER root
ARG GF_INSTALL_IMAGE_RENDERER_PLUGIN="true"
ARG GF_INSTALL_PLUGINS="true"
ENV GF_PATHS_PLUGINS="/var/lib/grafana-plugins"
LABEL version="9.5.12.20231025"
LABEL release="grafana-custom"
LABEL maintainer="marcinbojko"
SHELL ["/bin/ash", "-euo", "pipefail", "-c"]
HEALTHCHECK --interval=30s --timeout=15s --retries=3 CMD [ "curl","localhost:3000/healthz" ]
RUN mkdir -p "$GF_PATHS_PLUGINS" \
    && chown -R 472:472 "$GF_PATHS_PLUGINS" \
    && apk add --no-cache curl jq \
    && rm -rf /tmp/*
USER grafana

# shellcheck SC2026
# Array of plugin slugs to skip during installation

RUN if [ "$GF_INSTALL_PLUGINS" = "true" ]; then \
    PLUGINS_TO_SKIP="bsull-materialize-datasource bsull-console-datasource gabrielthomasjacobs-zendesk-datasource grafana-opcua-datasource"; \
    PLUGINS=$(curl -s https://grafana.net/api/plugins?orderBy=name | jq -r '.items[] | select(.internal==false and .status=="active") | .slug' | tr -d '"'); \
    for plugin in $PLUGINS; do \
        SKIP=false; \
        for skip_plugin in $PLUGINS_TO_SKIP; do \
            if [ "$plugin" = "$skip_plugin" ]; then \
                echo "Skipping plugin: $plugin"; \
                SKIP=true; \
                break; \
            fi; \
        done; \
        if [ "$SKIP" = "true" ]; then \
            continue; \
        fi; \
        echo "Installing plugin: $plugin"; \
        grafana-cli --pluginsDir "$GF_PATHS_PLUGINS" plugins install "$plugin" || true; \
    done; \
fi
