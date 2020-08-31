locals {
  entity_id = element(split("/", okta_app_saml.okta_asa.entity_key), length(split("/", okta_app_saml.okta_asa.entity_key)) - 1)
  base_url  = join("/", slice(split("/", okta_app_saml.okta_asa.http_post_binding), 0, 3))
}

output "okta_asa_metadata" {
  value =  "${local.base_url}/app/${local.entity_id}/sso/saml/metadata"
}

output "okta_groups" {
  value = [
    okta_group.platform_asa_push.name
  ]
}
