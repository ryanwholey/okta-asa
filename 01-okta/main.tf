resource "okta_app_saml" "okta_asa" {
  label = "Okta Advanced Server Access"

  preconfigured_app          = "scaleft"
  response_signed            = false
  status                     = "ACTIVE"
  user_name_template         = "$${source.login}"
  user_name_template_type    = "BUILT_IN"

  app_settings_json = jsonencode({
    audRestriction = "${var.base_url}/v1/teams/${var.oktaasa_team}"
    baseUrl        = var.base_url
  })

  features = [
    "GROUP_PUSH",
    "PUSH_NEW_USERS",
    "PUSH_PROFILE_UPDATES",
    "PUSH_USER_DEACTIVATION",
    "REACTIVATE_USERS",
    "SCIM_PROVISIONING",
  ]

  lifecycle {
    # groups managed by okta_app_group_assignment
    ignore_changes = [
      groups,
      users
    ]
  }
}

resource "okta_group" "platform" {
  name        = "Platform"
  description = "Platform users"

  users = [
    for user in data.okta_user.platform :
    user.id
  ]
}
# "Verify that the group you pushed is not the same one you used to assign and provision 
# users to the app. Using the same Okta group for assignments and for group push is not currently supported." 
# https://help.okta.com/en/prod/Content/Topics/users-groups-profiles/usgp-group-push-troubleshoot.htm#:~:text=Verify%20that%20the%20group%20you,push%20is%20not%20currently%20supported.&text=To%20recover%2C%20you%20must%20delete,reinstate%20the%20target%20app%20memberships.

resource "okta_group" "platform_asa_push" {
  name        = "platform-asa-push"
  description = "Platform users push group"

  users = [
    for user in data.okta_user.platform :
    user.id
  ]
}

resource "okta_app_group_assignment" "platform" {
  app_id   = okta_app_saml.okta_asa.id
  group_id = okta_group.platform.id
}

data "okta_users" "platform_search" {
  search {
    name       = "profile.division"
    value      = "Platform"
    comparison = "sw"
  }
}

data "okta_user" "platform" {
  for_each = toset([for user in data.okta_users.platform_search.users : user.email])

  search {
    name  = "profile.email"
    value = each.value
  }
}
