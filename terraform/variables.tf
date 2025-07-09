variable "environment" {
  type        = string
  description = "Environment"
  default     = "Dev"
}
variable "project" {
  type        = string
  description = "Project Name"
}
variable "image" {
  type        = string
  description = "App Docker image"
  default     = "docker.io/nzorro/concert_app"
}
variable "POSTGRES_PASSWORD" {
  sensitive = true
  default   = ""
}