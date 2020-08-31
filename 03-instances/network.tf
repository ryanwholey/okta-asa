
data "aws_availability_zones" "available" {
  state = "available"
}

module "network" {
  source = "./modules/network"

  cidr   = var.cidr
  azs    = slice([ for az in data.aws_availability_zones.available.names : az], 0, 2)
  prefix = var.environment
}
