ARG GRAFANA_VERSION="11.6.7"
FROM grafana/grafana:${GRAFANA_VERSION}
USER root
ARG GF_INSTALL_IMAGE_RENDERER_PLUGIN="false"
ARG GF_INSTALL_PLUGINS="true"
ENV GF_PATHS_PLUGINS="/var/lib/grafana-plugins"
LABEL version="11.6.7.20251023"
LABEL release="grafana-custom"
LABEL maintainer="marcinbojko"
SHELL ["/bin/ash", "-euo", "pipefail", "-c"]
HEALTHCHECK --interval=30s --timeout=15s --retries=3 CMD [ "curl","localhost:3000/healthz" ]
RUN mkdir -p "$GF_PATHS_PLUGINS" \
    && chown -R 472:472 "$GF_PATHS_PLUGINS" \
    && apk add --no-cache curl jq \
    && rm -rf /tmp/*
USER grafana

RUN VERSION=$(curl -sL https://api.github.com/repos/VictoriaMetrics/victoriametrics-datasource/releases/latest|jq -r .tag_name); \
    echo "$VERSION"; \
    curl -L https://github.com/VictoriaMetrics/victoriametrics-datasource/releases/download/"$VERSION"/victoriametrics-metrics-datasource-"$VERSION".tar.gz -o /tmp/plugin.tar.gz; \
    tar -xf /tmp/plugin.tar.gz -C /tmp; \
    mv /tmp/victoriametrics-metrics-datasource "$GF_PATHS_PLUGINS"/; \
    rm /tmp/plugin.tar.gz; \
    ls -lah "$GF_PATHS_PLUGINS";\
    sleep 5;

RUN VERSION=$(curl -sL https://api.github.com/repos/VictoriaMetrics/victorialogs-datasource/releases/latest|jq -r .tag_name); \
    echo "$VERSION"; \
    curl -L https://github.com/VictoriaMetrics/victorialogs-datasource/releases/download/"$VERSION"/victoriametrics-logs-datasource-"$VERSION".tar.gz -o /tmp/plugin.tar.gz; \
    tar -xf /tmp/plugin.tar.gz -C /tmp; \
    mv /tmp/victoriametrics-logs-datasource "$GF_PATHS_PLUGINS"/; \
    rm /tmp/plugin.tar.gz; \
    ls -lah "$GF_PATHS_PLUGINS";\
    sleep 5;


# shellcheck SC2026
# Array of plugin slugs to skip during installation

RUN if [ "$GF_INSTALL_PLUGINS" = "true" ]; then \
    PLUGINS_TO_SKIP="bsull-materialize-datasource bsull-console-datasource gabrielthomasjacobs-zendesk-datasource grafana-opcua-datasource grafana-image-renderer"; \
    PLUGINS=$(curl -sL https://grafana.net/api/plugins?orderBy=name | jq -r '.items[] | select(.internal==false and .status=="active") | .slug' | tr -d '"'); \
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
        grafana cli --pluginsDir "$GF_PATHS_PLUGINS" plugins install "$plugin" || true; \
    done; \
    ls -lah "$GF_PATHS_PLUGINS";\
    if [ -e "$GF_PATHS_PLUGINS"/grafana-image-renderer ]; then \
        echo "Removing grafana-image-renderer"; \
        rm -rfv "$GF_PATHS_PLUGINS"/grafana-image-renderer || true; \
    fi; \
    fi
