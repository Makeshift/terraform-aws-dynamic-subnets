##########################
#Create local for bastion hostname
##########################

locals {
  bastion_vpc_name  = var.vpc_id
  bastion_host_name = module.nat_instance_label.id
}

##########################
# Logic for security group and listeners
##########################
locals {
  hostport_whitelisted = join(",", var.bastion_cidr_blocks_whitelist_host) != ""
  hostport_healthcheck = "2222"
}

##########################
# Logic tests for  assume role vs same account
##########################
locals {
  assume_role_yes = var.bastion_assume_role_arn != "" ? 1 : 0
  assume_role_no  = var.bastion_assume_role_arn == "" ? 1 : 0
}

##########################
# Logic for using module default userdata sections or not
##########################
locals {
  custom_ssh_populate_no            = var.bastion_custom_ssh_populate == "" ? 1 : 0
  custom_authorized_keys_command_no = var.bastion_custom_authorized_keys_command == "" ? 1 : 0
  custom_docker_setup_no            = var.bastion_custom_docker_setup == "" ? 1 : 0
  custom_systemd_no                 = var.bastion_custom_systemd == "" ? 1 : 0
}

##########################
# Logic for using bastion_cidr_blocks_whitelist_service ONLY if provided
##########################

locals {
  cidr_blocks_whitelist_service_yes = join(",", var.bastion_cidr_blocks_whitelist_service) != "" ? 1 : 0
}

##########################
# Construct route53 name for historical behaviour where used
##########################

# locals {
#   route53_name_components = "${local.bastion_host_name}-${var.service_name}.${var.dns_domain}"
# }
