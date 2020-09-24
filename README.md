# grafana-custom

## Usage

```yaml
version: "3.8"
services:
  grafana:
    restart: unless-stopped
    image: marcinbojko/grafana-custom:latest
    ports:
     - "3000:3000"
    volumes:
      - grafana_lib:/var/lib/grafana
      - grafana_log:/var/log/grafana
      - grafana_etc:/etc/grafana
volumes:
  grafana_lib: {}
  grafana_log: {}
  grafana_etc: {}
```

## To Do

* rework plugin part to make image thinner
