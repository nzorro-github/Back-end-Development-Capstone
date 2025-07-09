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
variable "picture_service_port" {
  type = number
  default = 3000
}
variable "song_service_port" {
  type = number
  default = 4000
}
variable "POSTGRES_PASSWORD" {
  sensitive = true
  default   = ""
}
