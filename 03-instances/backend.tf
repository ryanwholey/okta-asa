data "terraform_remote_state" "asa" {
  backend = "local"

  config = {
    path = "${path.module}/../02-asa/terraform.tfstate"
  }
}
