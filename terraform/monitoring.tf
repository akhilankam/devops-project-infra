# Delay resource to ensure EKS is ready
resource "null_resource" "wait_for_eks" {
  # Ensure it runs after the EKS cluster is created
  depends_on = [module.eks]

  provisioner "local-exec" {
    command = "sleep 60" # wait for 60 seconds
  }
}
############################################
# Monitoring Namespace
############################################
resource "kubernetes_namespace_v1" "monitoring" {
  metadata {
    name = "monitoring"
  }

  # Ensure EKS control plane is ready
  depends_on = [null_resource.wait_for_eks]
}

resource "kubernetes_config_map_v1" "grafana_dashboards_1" {
  depends_on = [kubernetes_namespace_v1.monitoring]
  metadata {
    name      = "grafana-custom-dashboards-1"
    namespace = kubernetes_namespace_v1.monitoring.metadata[0].name
  }

  data = {
    "Pod-Stats.json" = file("${path.module}/dashboards/Pod-Stats.json")
  }
}

resource "kubernetes_config_map_v1" "grafana_dashboards_2" {
  depends_on = [kubernetes_namespace_v1.monitoring]
  metadata {
    name      = "grafana-custom-dashboards-2"
    namespace = kubernetes_namespace_v1.monitoring.metadata[0].name
  }

  data = {
    "sample-cpu-dashboard.json" = <<-EOT
    {
  "id": null,
  "uid": "sample-cpu-dashboard",
  "title": "Sample CPU Dashboard",
  "timezone": "browser",
  "schemaVersion": 38,
  "version": 1,
  "refresh": "30s",
  "panels": [
    {
      "id": 1,
      "type": "timeseries",
      "title": "CPU Usage (Node)",
      "gridPos": {
        "x": 0,
        "y": 0,
        "w": 12,
        "h": 8
      },
      "targets": [
        {
          "expr": "sum(rate(node_cpu_seconds_total{mode!=\"idle\"}[5m])) by (instance)",
          "refId": "A"
        }
      ],
      "datasource": {
        "type": "prometheus",
        "uid": "prometheus"
      }
    }
  ]
}
EOT
  }
}

############################################
# Prometheus + Grafana + Alertmanager
############################################
resource "helm_release" "monitoring" {
  name       = "monitoring"
  namespace  = kubernetes_namespace_v1.monitoring.metadata[0].name
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = "58.3.0"
  depends_on = [kubernetes_namespace_v1.monitoring]
  values = [
    yamlencode({

      ####################################
      # Prometheus (low-cost config)
      ####################################
      prometheus = {
        prometheusSpec = {
          retention = "2d"

          resources = {
            requests = {
              cpu    = "100m"
              memory = "256Mi"
            }
            limits = {
              cpu    = "300m"
              memory = "512Mi"
            }
          }
        }
      }

      ####################################
      # Grafana
      ####################################
      grafana = {
        enabled       = true
        adminPassword = "admin" # change later

        dashboardProviders = {
          "dashboardproviders.yaml" = {
            apiVersion = 1
            providers = [
              {
                name            = "custom-1"
                orgId           = 1
                folder          = "Custom_Dashboards_1"
                type            = "file"
                disableDeletion = false
                editable        = true
                options = {
                  path = "/var/lib/grafana/dashboards/custom-1"
                }
              },
              {
                name            = "custom-2"
                orgId           = 1
                folder          = "Custom_Dashboards_2"
                type            = "file"
                disableDeletion = false
                editable        = true
                options = {
                  path = "/var/lib/grafana/dashboards/custom-2"
                }
              }
            ]
          }
        }

        dashboardsConfigMaps = {
          custom-1 = kubernetes_config_map_v1.grafana_dashboards_1.metadata[0].name
          custom-2 = kubernetes_config_map_v1.grafana_dashboards_2.metadata[0].name
        }

        resources = {
          requests = {
            cpu    = "50m"
            memory = "128Mi"
          }
          limits = {
            cpu    = "200m"
            memory = "256Mi"
          }
        }

        service = {
          type = "ClusterIP"
        }
      }

      ####################################
      # Alertmanager (enabled)
      ####################################
      alertmanager = {
        enabled = true

        alertmanagerSpec = {
          replicas = 1

          resources = {
            requests = {
              cpu    = "50m"
              memory = "128Mi"
            }
            limits = {
              cpu    = "200m"
              memory = "256Mi"
            }
          }
        }
      }

      ####################################
      # Other components (defaults)
      ####################################
      kubeStateMetrics = {
        enabled = true
      }

      nodeExporter = {
        enabled = true
      }
    })
  ]
}