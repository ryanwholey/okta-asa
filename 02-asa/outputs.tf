output "enrollment_token" {
  value = oktaasa_enrollment_token.enrollment_token.token_value
}

output "project_name" {
  value = oktaasa_project.playground.project_name
}
