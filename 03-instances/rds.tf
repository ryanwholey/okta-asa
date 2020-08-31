# resource "aws_db_subnet_group" "postgres" {
#   name       = "postgres"
#   subnet_ids = module.network.private_subnet_ids
# }

# resource "aws_security_group" "postgres" {
#   name = "${var.environment}-postgres"
#   vpc_id = module.network.vpc_id
#   ingress {
#       from_port   = 5432
#       to_port     = 5432
#       protocol    = "tcp"
#       cidr_blocks = [module.network.cidr]
#   }
#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
# }

# resource "aws_db_instance" "postgres" {
#   allocated_storage                     = 20
#   allow_major_version_upgrade           = false
#   apply_immediately                     = true
#   backup_retention_period               = 0
#   ca_cert_identifier                    = "rds-ca-2019"
#   db_subnet_group_name                  = aws_db_subnet_group.postgres.name
#   deletion_protection                   = false
#   engine                                = "postgres"
#   engine_version                        = "11"

#   identifier_prefix                     = "okta-asa-"
#   instance_class                        = "db.t3.small"


#   monitoring_interval                   = 0
#   multi_az                              = false
#   name                                  = "asa"

#   password                              = "password"
#   username                              = "asa"

#   performance_insights_enabled          = false
#   performance_insights_retention_period = 0
#   port                                  = 5432

#   storage_encrypted                     = true
#   storage_type                          = "gp2"
#   vpc_security_group_ids                = [aws_security_group.postgres.id]

#   skip_final_snapshot                   = true
# }

# output "rds" {
#   value = {
#     endpoint = aws_db_instance.postgres.endpoint
#     username = aws_db_instance.postgres.username
#     password = aws_db_instance.postgres.password
#   }
# }
