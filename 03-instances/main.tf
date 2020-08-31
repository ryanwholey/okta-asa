resource "aws_key_pair" "admin" {
  key_name   = "admin"
  public_key = file("~/.ssh/id_rsa.pub")
}

data "aws_route53_zone" "primary" {
  name = var.hosted_zone
}
