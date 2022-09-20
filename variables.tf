variable "aws_region" {
  default = "us-east-1"
}
variable "aws_ecr_repository" {
  description = "The URL of the docker image"
  type        = string
  default     = "grafana/grafana"
}
variable "fargate_cpu" {
  default = 10
  type    = number
}
variable "fargate_memory" {
  default = 1024
  type    = number
}
variable "task_cpu" {
  default = 10
  type    = number
}
variable "task_memory" {
  default = 1024
  type    = number
}
variable "certificate_domain" {
  description = "The domain name of an existing certificate issued by ACM"
  type        = string
}
variable "route_53_zone" {
  description = "The DNS zone to place our host record"
  type        = string
}
variable "allowed_public_cidr" {
  description = "The Network cidr range allowed to access Grafana"
  default     = "0.0.0.0/0"
}
variable "default_tags" {
  default = {}
}