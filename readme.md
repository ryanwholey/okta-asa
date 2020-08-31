Via Terraform
1) Create a SAML Okta ASA app, output the metadata URL
1) Ensure that you, the inital creator, are somehow assigned to the Okta app
1) Create new team on [scaleft](https://app.scaleft.com/r/select-team) and add the metadata URL, click authenticate

Manually in Okta ASA
1) Create an oktasaa service account user "terraform"
1) Copy secret key and key ID to be used along with your org name as env vars for the provider
1) Create a group called "terraform" and add terraform to it, grant the "terraform" group admin team roles

Manually in Okta
1) Head to the ASA Okta app in Okta and click Push Groups
1) Enable Provisioning > Authenticate with ASA (make sure you are an admin in ASA!)
1) When prompted create the user "Okta" to allow Okta to write groups in ASA
1) Activate Group Push on the groups you would like to link from Okta to ASA, click save
1) When the page reloads, click edit and enable "Create Users" "Update User Attributes" and "Deactivate Users", click Save
1) Head back to Push Groups and add the groups that you want to sync to ASA

Via Terraform
1) Now that the groups have been synced to ASA, create a server project/enrollment token and assign the pushed groups (by name) to the project, output the enrollment token
1) Create a server and in the init script, pass it the enrollment token

Research
- Ensure sft client is installed on computers (via FleetSmith?)
- Harden ubuntu or choose different AMI
- Ensure SSH flow is smooth when not logged in
- Fix hostname validation error when switching servers
- Server unenrollment on termination
- NLB in front of autoscaling group
- Can't add group rules to pushed groups
- HOLY SHIT "Verify that the group you pushed is not the same one you used to assign and provision users to the app. Using the same Okta group for assignments and for group push is not currently supported." https://help.okta.com/en/prod/Content/Topics/users-groups-profiles/usgp-group-push-troubleshoot.htm#:~:text=Verify%20that%20the%20group%20you,push%20is%20not%20currently%20supported.&text=To%20recover%2C%20you%20must%20delete,reinstate%20the%20target%20app%20memberships.






