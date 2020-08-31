resource "oktaasa_project" "playground" {
  project_name = "playground"
}

resource "oktaasa_enrollment_token" "enrollment_token" {
  project_name = oktaasa_project.playground.project_name
  description  = "playground enrollment token"
}

resource "oktaasa_assign_group" "playground_platform" {
  for_each = toset(data.terraform_remote_state.okta.outputs.okta_groups)

  project_name  = oktaasa_project.playground.project_name
  group_name    = each.value
  server_access = true
  server_admin  = true

  create_server_group = true
}
