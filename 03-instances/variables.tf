variable "sftd_version" {
  type    = string
  default = "1.40.1"
}

variable "environment" {
  default = "playground"
}

variable "cidr" {
  default = "10.0.0.0/16"
}

variable "hosted_zone" {}

variable "instance_type" {
  default = "t3.small"
}

variable "instance_count" {
  default = 2
}

variable "oktaasa_team" {}
variable "oktaasa_key" {}
variable "oktaasa_key_secret" {}
variable "bucket_prefix" {}