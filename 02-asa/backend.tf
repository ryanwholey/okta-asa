data "terraform_remote_state" "okta" {
  backend = "local"

  config = {
    path = "${path.module}/../01-okta/terraform.tfstate"
  }
}