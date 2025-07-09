resource "kubernetes_service_account" "sa" {
  metadata {
    name      = "${var.project}-service-account"
    namespace = var.environment
  }
  image_pull_secret {
    name = "regcred"
  }

  automount_service_account_token = true
}

resource "kubernetes_secret_v1" "secret" {
  metadata {
    name      = "${var.project}-secret"
    namespace = var.environment
  }
  data = {
    POSTGRES_PASSWORD = base64encode(var.POSTGRES_PASSWORD)
  }
}

resource "kubernetes_deployment_v1" "postgres" {
  metadata {
    name      = "${var.project}-postgres"
    namespace = var.environment
    labels = {
      app = "${var.project}-db"
      env = var.environment
    }
  }
  depends_on = [kubernetes_secret_v1.secret]

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "${var.project}-db"
        env = var.environment
      }
    }

    template {
      metadata {
        labels = {
          app = "${var.project}-db"
          env = var.environment
        }
      }

      spec {
        container {
          image = "postgres:14.18"
          name  = "postgres-ctr"

          env_from {
            secret_ref {
              name = kubernetes_secret_v1.secret.metadata[0].name
            }
          }

          resources {
            limits = {
              cpu    = "0.5"
              memory = "512Mi"
            }
            requests = {
              cpu    = "250m"
              memory = "50Mi"
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_deployment_v1" "django" {
  metadata {
    name      = "${var.project}-webapp"
    namespace = var.environment
    labels = {
      app = "${var.project}-App"
      env = var.environment
    }
  }

  depends_on = [kubernetes_deployment_v1.postgres]

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "${var.project}-App"
        env = var.environment
      }
    }

    template {
      metadata {
        labels = {
          app = "${var.project}-App"
          env = var.environment
        }
      }

      spec {
        service_account_name = kubernetes_service_account.sa.metadata[0].name
        container {
          image = var.image
          name  = "${var.project}-ctr"

          resources {
            limits = {
              cpu    = "1.0"
              memory = "512Mi"
            }
            requests = {
              cpu    = "512m"
              memory = "50Mi"
            }
          }
        }
      }
    }
  }
}
