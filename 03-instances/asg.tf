resource "aws_security_group" "bastion" {
  name = "${var.environment}-bastion"
  vpc_id = module.network.vpc_id
  ingress {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }
}

resource "aws_launch_template" "bastion" {
  name_prefix = "${var.environment}-bastion-"

  image_id = data.aws_ami.ubuntu.id

  instance_type = var.instance_type

  vpc_security_group_ids = [aws_security_group.bastion.id]

  user_data = base64encode(templatefile("${path.module}/templates/init.sh", {
    enrollment_token = data.terraform_remote_state.asa.outputs.enrollment_token
    sftd_version     = var.sftd_version
    hostname         = "${var.environment}-bastion"
    alt_names        = "[${join(", ", [for item in ["bastion.${var.hosted_zone}"]: "\"${item}\""])}]"
  }))

  tag_specifications {
    resource_type = "instance"

    tags = {
      Environment = var.environment
    }
  }
}

data "aws_iam_policy_document" "trust_autoscaling" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type        = "Service"
      identifiers = ["autoscaling.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "unenroll_write" {
  name = "${var.environment}-okta-asa-unenroll-write"

  assume_role_policy = data.aws_iam_policy_document.trust_autoscaling.json
}

resource "aws_iam_role_policy_attachment" "unenroll_writes" {
  role       = aws_iam_role.unenroll_write.name
  policy_arn = aws_iam_policy.unenroll_write.arn
}

resource "aws_autoscaling_group" "bastion" {
  name                      = "${var.environment}-bastion"
  max_size                  = var.instance_count
  min_size                  = var.instance_count
  desired_capacity          = var.instance_count

  launch_template {
    id      = aws_launch_template.bastion.id
    version = "$Latest"
  } 

  vpc_zone_identifier       = module.network.public_subnet_ids

  initial_lifecycle_hook {
    name                 = "unenroll-okta-asa"
    default_result       = "CONTINUE"
    heartbeat_timeout    = 2000
    lifecycle_transition = "autoscaling:EC2_INSTANCE_TERMINATING"

    notification_metadata = jsonencode({
      project_name = data.terraform_remote_state.asa.outputs.project_name
    })

    notification_target_arn = aws_sqs_queue.unenrollment_queue.arn
    role_arn                = aws_iam_role.unenroll_write.arn
  }

  tag {
    key                 = "Name"
    value               = "${var.environment}-bastion"
    propagate_at_launch = true
  }

  timeouts {
    delete = "15m"
  }
}
