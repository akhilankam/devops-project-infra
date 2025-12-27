############################################
# Monitoring Namespace
############################################
resource "kubernetes_namespace_v1" "monitoring" {
  metadata {
    name = "monitoring"
  }

  # Ensure EKS control plane is ready
  depends_on = [module.eks]
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