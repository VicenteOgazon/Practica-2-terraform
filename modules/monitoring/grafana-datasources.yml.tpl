apiVersion: 1

datasources:
  - name: Prometheus
    uid: prometheus
    type: prometheus
    access: proxy
    url: http://${prometheus_host}:${prometheus_port}
    isDefault: true
    editable: false

  - name: Loki
    type: loki
    access: proxy
    url: http://${loki_host}:${loki_port}
    isDefault: false