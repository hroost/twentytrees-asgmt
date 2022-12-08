resource "kubernetes_manifest" "namespace_twentytrees_asgmt" {
  manifest = {
    "apiVersion" = "v1"
    "kind" = "Namespace"
    "metadata" = {
      "labels" = {
        "name" = var.namespace_name
      }
      "name" = var.namespace_name
    }
  }
}

resource "kubernetes_manifest" "persistentvolumeclaim_twentytrees_asgmt_analyzer_satelite_data_pvc" {
  depends_on = [
    kubernetes_manifest.namespace_twentytrees_asgmt
  ]
  manifest = {
    "apiVersion" = "v1"
    "kind" = "PersistentVolumeClaim"
    "metadata" = {
      "name" = "${var.app_name}-satelite-data-pvc"
      "namespace" = var.namespace_name
    }
    "spec" = {
      "accessModes" = [
        "ReadWriteOnce",
      ]
      "resources" = {
        "requests" = {
          "storage" = var.data_storage_size
        }
      }
    }
  }
}

resource "kubernetes_manifest" "persistentvolumeclaim_twentytrees_asgmt_analyzer_model_data_pvc" {
  depends_on = [
    kubernetes_manifest.namespace_twentytrees_asgmt
  ]
  manifest = {
    "apiVersion" = "v1"
    "kind" = "PersistentVolumeClaim"
    "metadata" = {
      "name" = "${var.app_name}-model-data-pvc"
      "namespace" = var.namespace_name
    }
    "spec" = {
      "accessModes" = [
        "ReadWriteOnce",
      ]
      "resources" = {
        "requests" = {
          "storage" = var.data_storage_size
        }
      }
    }
  }
}

resource "kubernetes_manifest" "deployment_twentytrees_asgmt_analyzer_depl" {
  manifest = {
    "apiVersion" = "apps/v1"
    "kind" = "Deployment"
    "metadata" = {
      "labels" = {
        "app" = var.app_name
      }
      "name" = "${var.app_name}-depl"
      "namespace" = var.namespace_name
    }
    "spec" = {
      "replicas" = 1
      "selector" = {
        "matchLabels" = {
          "app" = var.app_name
        }
      }
      "template" = {
        "metadata" = {
          "labels" = {
            "app" = var.app_name
          }
        }
        "spec" = {
          "containers" = [
            {
              "image" = "${var.app_image}:${var.app_version}"
              "livenessProbe" = {
                "httpGet" = {
                  "path" = "/health"
                  "port" = 80
                }
                "initialDelaySeconds" = 5
                "periodSeconds" = 5
              }
              "name" = "tif-${var.app_name}"
              "ports" = [
                {
                  "containerPort" = 80
                },
              ]
              "resources" = {
                "requests" = {
                  "cpu" = "500m"
                }
              }
              "volumeMounts" = [
                {
                  "mountPath" = "/code/app/satelite"
                  "name" = "satelite-data"
                  "readOnly" = true
                },
                {
                  "mountPath" = "/code/app/model"
                  "name" = "model-data"
                  "readOnly" = true
                },
              ]
            },
          ]
          "initContainers" = [
            {
              "command" = [
                "/bin/sh",
                "-c",
                "curl '${var.satelite_test_file_url}' -o /data/Sentinel2L2A_sen2cor_18TUR_20180812_clouds=5.3%_area=99%.tif -z /data/Sentinel2L2A_sen2cor_18TUR_20180812_clouds=5.3%_area=99%.tif -v && curl '${var.test_crop_file_url}' -o /data/${element(split("/",var.test_crop_file_url), length(split("/",var.test_crop_file_url)) - 1)} -z /data/${element(split("/",var.test_crop_file_url), length(split("/",var.test_crop_file_url)) - 1)} -v",
                # "curl '${var.satelite_test_file_url}' -o /data/${element(split("/",var.satelite_test_file_url), length(split("/",var.satelite_test_file_url)) - 1)} -z /data/${element(split("/",var.satelite_test_file_url), length(split("/",var.satelite_test_file_url)) - 1)} -v && curl '${var.test_crop_file_url}' -o /data/${element(split("/",var.test_crop_file_url), length(split("/",var.test_crop_file_url)) - 1)} -z /data/${element(split("/",var.test_crop_file_url), length(split("/",var.test_crop_file_url)) - 1)} -v",
              ]
              "image" = "yauritux/busybox-curl"
              "name" = "fetch-satelite-data"
              "volumeMounts" = [
                {
                  "mountPath" = "/data"
                  "name" = "satelite-data"
                },
              ]
            },
            {
              "command" = [
                "/bin/sh",
                "-c",
                "curl '${var.model_test_file_url}' -o /data/live_model.pickle -z /data/live_model.pickle -v",
                # "curl '${var.model_test_file_url}' -o /data/${element(split("/",var.model_test_file_url), length(split("/",var.model_test_file_url)) - 1)} -z /data/${element(split("/",var.model_test_file_url), length(split("/",var.model_test_file_url)) - 1)} -v",
              ]
              "image" = "yauritux/busybox-curl"
              "name" = "fetch-model-data"
              "volumeMounts" = [
                {
                  "mountPath" = "/data"
                  "name" = "model-data"
                },
              ]
            },
          ]
          "volumes" = [
            {
              "name" = "satelite-data"
              "persistentVolumeClaim" = {
                "claimName" = "${var.app_name}-satelite-data-pvc"
              }
            },
            {
              "name" = "model-data"
              "persistentVolumeClaim" = {
                "claimName" = "${var.app_name}-model-data-pvc"
              }
            },
          ]
        }
      }
    }
  }
}

resource "kubernetes_manifest" "service_twentytrees_asgmt_analyzer_svc" {
  manifest = {
    "apiVersion" = "v1"
    "kind" = "Service"
    "metadata" = {
      "name" = "${var.app_name}-svc"
      "namespace" = var.namespace_name
    }
    "spec" = {
      "ports" = [
        {
          "port" = var.app_port
          "protocol" = "TCP"
          "targetPort" = 80
        },
      ]
      "selector" = {
        "app" = var.app_name
      }
    }
  }
}

resource "kubernetes_manifest" "horizontalpodautoscaler_twentytrees_asgmt_analyzer_depl" {
  manifest = {
    "apiVersion" = "autoscaling/v2"
    "kind" = "HorizontalPodAutoscaler"
    "metadata" = {
      "name" = "${var.app_name}-depl"
      "namespace" = var.namespace_name
    }
    "spec" = {
      "maxReplicas" = 5
      "metrics" = [
        {
          "resource" = {
            "name" = "cpu"
            "target" = {
              "averageUtilization" = 50
              "type" = "Utilization"
            }
          }
          "type" = "Resource"
        },
      ]
      "minReplicas" = 1
      "scaleTargetRef" = {
        "apiVersion" = "apps/v1"
        "kind" = "Deployment"
        "name" = "${var.app_name}-depl"
      }
    }
  }
}
