variable "kubeconfig_path" {
  type = string
}
variable "region" {
  description = "GCP region"
  type = string
}
variable "project_id" {
  description = "GCP project ID"
  type = string
}
variable "namespace_name" {
  type = string
}
variable "app_name" {
  type = string
}
variable "app_image" {
  type = string
}
variable "app_version" {
  type = string
}
variable "app_port" {
  type = number
}
variable "data_storage_size" {
  type = string
}
variable "autoscale_min" {
  type = number
}
variable "autoscale_max" {
  type = number
}
variable "satelite_test_file_url" {
  type = string
}
variable "model_test_file_url" {
  type = string
}
variable "test_crop_file_url" {
  type = string
}
