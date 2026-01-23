{
  "id": null,
  "uid": null,
  "title": "${title}",
  "tags": ["terraform", "docker", "flask"],
  "timezone": "browser",
  "schemaVersion": 38,
  "version": 1,
  "refresh": "10s",
  "time": { "from": "now-30m", "to": "now" },
  "templating": {
    "list": [
      {
        "type": "query",
        "name": "instance",
        "label": "Instancia web",
        "datasource": { "type": "prometheus", "uid": "prometheus" },
        "query": { "query": "label_values(up{job=\"web_app\"}, instance)", "refId": "Q1" },
        "multi": true,
        "includeAll": true,
        "allValue": ".*",
        "refresh": 2,
        "sort": 1
      }
    ]
  },
  "panels": [
    {
      "type": "row",
      "title": "Overview",
      "gridPos": { "x": 0, "y": 0, "w": 24, "h": 1 },
      "collapsed": false,
      "panels": []
    },
    {
      "type": "stat",
      "title": "Instancias web UP",
      "gridPos": { "x": 0, "y": 1, "w": 6, "h": 5 },
      "datasource": { "type": "prometheus", "uid": "prometheus" },
      "targets": [
        {
          "refId": "A",
          "expr": "sum(up{job=\"web_app\", instance=~\"$instance\"})"
        }
      ],
      "options": {
        "reduceOptions": { "calcs": ["lastNotNull"], "values": false },
        "orientation": "auto",
        "textMode": "auto",
        "colorMode": "value",
        "graphMode": "area"
      }
    },
    {
      "type": "stat",
      "title": "Peticiones (RPS total)",
      "gridPos": { "x": 6, "y": 1, "w": 6, "h": 5 },
      "datasource": { "type": "prometheus", "uid": "prometheus" },
      "targets": [
        {
          "refId": "A",
          "expr": "sum(rate(flask_http_request_total{job=\"web_app\", instance=~\"$instance\"}[1m]))"
        }
      ],
      "options": {
        "reduceOptions": { "calcs": ["lastNotNull"], "values": false },
        "orientation": "auto",
        "textMode": "auto",
        "colorMode": "value",
        "graphMode": "area"
      }
    },
    {
      "type": "stat",
      "title": "Errores 5xx (RPS total)",
      "gridPos": { "x": 12, "y": 1, "w": 6, "h": 5 },
      "datasource": { "type": "prometheus", "uid": "prometheus" },
      "targets": [
        {
          "refId": "A",
          "expr": "sum(rate(flask_http_request_total{job=\"web_app\", instance=~\"$instance\", status=~\"5..\"}[5m])) OR sum(rate(flask_http_request_total{job=\"web_app\", instance=~\"$instance\", code=~\"5..\"}[5m]))"
        }
      ],
      "options": {
        "reduceOptions": { "calcs": ["lastNotNull"], "values": false },
        "orientation": "auto",
        "textMode": "auto",
        "colorMode": "value",
        "graphMode": "area"
      }
    },
    {
      "type": "stat",
      "title": "CPU total (web) [cores aprox]",
      "gridPos": { "x": 18, "y": 1, "w": 6, "h": 5 },
      "datasource": { "type": "prometheus", "uid": "prometheus" },
      "targets": [
        {
          "refId": "A",
          "expr": "sum(rate(process_cpu_seconds_total{job=\"web_app\", instance=~\"$instance\"}[1m]))"
        }
      ],
      "options": {
        "reduceOptions": { "calcs": ["lastNotNull"], "values": false },
        "orientation": "auto",
        "textMode": "auto",
        "colorMode": "value",
        "graphMode": "area"
      }
    },

    {
      "type": "row",
      "title": "Recursos por instancia",
      "gridPos": { "x": 0, "y": 6, "w": 24, "h": 1 },
      "collapsed": false,
      "panels": []
    },
    {
      "type": "timeseries",
      "title": "CPU (rate process_cpu_seconds_total)",
      "gridPos": { "x": 0, "y": 7, "w": 12, "h": 8 },
      "datasource": { "type": "prometheus", "uid": "prometheus" },
      "targets": [
        {
          "refId": "A",
          "expr": "rate(process_cpu_seconds_total{job=\"web_app\", instance=~\"$instance\"}[1m])"
        }
      ],
      "options": {
        "legend": { "showLegend": true, "displayMode": "list", "placement": "bottom" }
      }
    },
    {
      "type": "timeseries",
      "title": "Memoria (process_resident_memory_bytes)",
      "gridPos": { "x": 12, "y": 7, "w": 12, "h": 8 },
      "datasource": { "type": "prometheus", "uid": "prometheus" },
      "targets": [
        {
          "refId": "A",
          "expr": "process_resident_memory_bytes{job=\"web_app\", instance=~\"$instance\"}"
        }
      ],
      "options": {
        "legend": { "showLegend": true, "displayMode": "list", "placement": "bottom" }
      }
    },
    {
      "type": "row",
      "title": "HTTP requests",
      "gridPos": { "x": 0, "y": 22, "w": 24, "h": 1 },
      "collapsed": false,
      "panels": []
    },
    {
      "type": "timeseries",
      "title": "Requests",
      "gridPos": { "x": 0, "y": 23, "w": 12, "h": 8 },
      "datasource": { "type": "prometheus", "uid": "prometheus" },
      "targets": [
        {
          "refId": "A",
          "expr": "sum(rate(flask_http_request_total{job=\"web_app\", instance=~\"$instance\"}[1m])) by (instance)"
        }
      ],
      "options": {
        "legend": { "showLegend": true, "displayMode": "list", "placement": "bottom" }
      }
    },
    {
      "type": "timeseries",
      "title": "Errores 5xx",
      "gridPos": { "x": 12, "y": 23, "w": 12, "h": 8 },
      "datasource": { "type": "prometheus", "uid": "prometheus" },
      "targets": [
        {
          "refId": "A",
          "expr": "sum(rate(flask_http_request_total{job=\"web_app\", instance=~\"$instance\", status=~\"5..\"}[5m])) by (instance) OR sum(rate(flask_http_request_total{job=\"web_app\", instance=~\"$instance\", code=~\"5..\"}[5m])) by (instance)"
        }
      ],
      "options": {
        "legend": { "showLegend": true, "displayMode": "list", "placement": "bottom" }
      }
    }
  ]
}