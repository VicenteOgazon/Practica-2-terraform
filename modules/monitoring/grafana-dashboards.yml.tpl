apiVersion: 1

providers:
  - name: default
    orgId: 1
    folder: "Terraform"
    type: file
    disableDeletion: false
    editable: true
    updateIntervalSeconds: 10
    options:
      path: /etc/grafana/provisioning/dashboards
      foldersFromFilesStructure: false