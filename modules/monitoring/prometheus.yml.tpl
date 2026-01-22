global:
  scrape_interval: 15s

%{ if alerting_enabled ~}
alerting:
  alertmanagers:
    - static_configs:
        - targets:
            - "${alertmanager_host}:${alertmanager_port}"
%{ endif ~}

rule_files:
  - "/etc/prometheus/alert-rules.yml"

scrape_configs:
  - job_name: "web_app"
    metrics_path: "/metrics"
    static_configs:
      - targets:
%{ for t in scrape_targets ~}
        - "${t}"
%{ endfor ~}

  - job_name: "cadvisor"
    metrics_path: "/metrics"
    static_configs:
      - targets:
        - "${cadvisor_name}:${cadvisor_port}"