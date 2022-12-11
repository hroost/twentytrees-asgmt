provider "google" {
  project = var.project_id
  region  = var.region
}

resource "helm_release" "nfs-server-provisioner" {
  name       = "nfs-server-provisioner"

  # repository = "https://raphaelmonrouzeau.github.io/charts/repository/"
  repository = "https://kvaps.github.io/charts"
  chart      = "nfs-server-provisioner"

  namespace = var.namespace_name

    set {
        name  = "persistence.enabled"
        value = "true"
    }

    set {
        name  = "persistence.accessMode"
        value = "ReadWriteOnce"
    }

    set {
        name  = "persistence.storageClass"
        value = "standard-rwo"
    }

    set {
        name  = "persistence.size"
        value = "10Gi"
    }
}
