locals {
  postgres_svc = "${var.project}-postgres-svc"
  picture_service_url = "http://${var.project}-picture-svc:${var.picture_service_port}"
  song_service_url = "http://${var.project}-song-svc:${var.song_service_port}"
}

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
    POSTGRES_HOST      = local.postgres_svc
    POSTGRES_PASSWORD  = base64encode(var.POSTGRES_PASSWORD)
    SUPERUSER_PASSWORD = var.POSTGRES_PASSWORD
    PICTURE_SERVICE_URL = local.picture_service_url
    SONG_SERVICE_URL = local.song_service_url
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
###############################################
# PostgreSQL K8S SERVICE
################################################
resource "kubernetes_service_v1" "postgres_svc" {
  metadata {
    name      = local.postgres_svc
    namespace = var.environment
  }

  spec {
    selector = {
      app = kubernetes_deployment_v1.postgres.spec[0].template[0].metadata[0].labels.app
      env = kubernetes_deployment_v1.postgres.spec[0].template[0].metadata[0].labels.env
    }
    type = "ClusterIP"
    port {
      target_port = 5432
      port        = 5432
      protocol    = "TCP"
    }
  }
}
###############################################
# DJANGO CONCERT APP K8S DEPLOYMENT
################################################
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

          env_from {
            secret_ref {
              name = kubernetes_secret_v1.secret.metadata[0].name
            }
          }

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

###############################################
# DJANGO CONCERT APP K8S SERVICE
################################################
resource "kubernetes_service_v1" "django_svc" {
  metadata {
    name      = "${var.project}-svc"
    namespace = var.environment
  }

  spec {
    selector = {
      app = kubernetes_deployment_v1.django.spec[0].template[0].metadata[0].labels.app
      env = kubernetes_deployment_v1.django.spec[0].template[0].metadata[0].labels.env

    }
    type = "ClusterIP"
    port {
      target_port = 8000
      port        = 8000
      protocol    = "TCP"
    }
  }
}