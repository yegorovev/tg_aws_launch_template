terraform {
  source = "github.com/yegorovev/tf_aws_launch_template.git"
}


locals {
  common  = read_terragrunt_config(find_in_parent_folders("common.hcl")).inputs.common
  env     = local.common.env
  profile = local.common.profile
  region  = local.common.region

  common_tags = jsonencode(local.common.tags)

  net                     = read_terragrunt_config(find_in_parent_folders("common.hcl")).inputs.net
  net_backet_remote_state = local.net.net_backet_remote_state
  net_key_remote_state    = local.net.net_key_remote_state
  net_remote_state_region = local.net.net_remote_state_region

  launch_template            = read_terragrunt_config(find_in_parent_folders("common.hcl")).inputs.launch_template
  lt_lock_table_remote_state = local.launch_template.lt_lock_table_remote_state
  lt_key_remote_state        = local.launch_template.lt_key_remote_state
  lt_backet_remote_state     = local.launch_template.lt_backet_remote_state
  lt_ami_id                  = try(local.launch_template.lt_ami_id, "")
  lt_default_ami             = local.launch_template.lt_default_ami
  lt_instance_type           = local.launch_template.lt_instance_type
  lt_launch_template_name    = local.launch_template.lt_launch_template_name
  lt_key_name                = try(local.launch_template.lt_key_name, "")
  lt_vpc_security_groups     = local.launch_template.lt_vpc_security_groups
}

remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    bucket         = local.lt_backet_remote_state
    key            = local.lt_key_remote_state
    region         = local.region
    encrypt        = true
    dynamodb_table = local.lt_lock_table_remote_state
  }
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  profile = "${local.profile}"
  region  = "${local.region}"
  default_tags {
    tags = jsondecode(<<INNEREOF
${local.common_tags}
INNEREOF
)
  }
}
EOF
}

inputs = {
  net_backet_remote_state = local.net_backet_remote_state
  net_key_remote_state    = local.net_key_remote_state
  net_remote_state_region = local.net_remote_state_region

  env                     = local.env
  lt_ami_id               = local.lt_ami_id
  lt_default_ami          = local.lt_default_ami
  lt_instance_type        = local.lt_instance_type
  lt_launch_template_name = local.lt_launch_template_name
  lt_key_name             = local.lt_key_name
  lt_vpc_security_groups  = local.lt_vpc_security_groups
}