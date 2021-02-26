module "nat_instance_label" {
  source  = "cloudposse/label/null"
  version = "0.24.1"

  attributes = ["nat", "instance"]

  context = module.this.context
}

data "aws_region" "current" {
}

locals {
  cidr_block               = var.cidr_block != "" ? var.cidr_block : join("", data.aws_vpc.default.*.cidr_block)
  nat_instance_enabled     = var.nat_instance_enabled ? 1 : 0
  nat_instance_count       = var.nat_instance_enabled ? length(var.availability_zones) : 0
  nat_instance_eip_count   = local.use_existing_eips ? 0 : local.nat_instance_count
  instance_eip_allocations = local.use_existing_eips ? data.aws_eip.nat_ips.*.id : aws_eip.nat_instance.*.id
}

resource "aws_security_group" "nat_instance" {
  count       = local.enabled ? local.nat_instance_enabled : 0
  name        = module.nat_instance_label.id
  description = "Security Group for NAT Instance"
  vpc_id      = var.vpc_id
  tags        = module.nat_instance_label.tags
}

resource "aws_security_group_rule" "nat_instance_egress" {
  count             = local.enabled ? local.nat_instance_enabled : 0
  description       = "Allow all egress traffic"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"] #tfsec:ignore:AWS007
  security_group_id = join("", aws_security_group.nat_instance.*.id)
  type              = "egress"
}

resource "aws_security_group_rule" "nat_instance_ingress" {
  count             = local.enabled ? local.nat_instance_enabled : 0
  description       = "Allow ingress traffic from the VPC CIDR block"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = [local.cidr_block]
  security_group_id = join("", aws_security_group.nat_instance.*.id)
  type              = "ingress"
}

# aws --region us-west-2 ec2 describe-images --owners amazon --filters Name="name",Values="amzn-ami-vpc-nat*" Name="virtualization-type",Values="hvm"
data "aws_ami" "nat_instance" {
  count       = local.enabled ? local.nat_instance_enabled : 0
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}


// https://docs.aws.amazon.com/vpc/latest/userguide/vpc-nat-comparison.html
// https://docs.aws.amazon.com/vpc/latest/userguide/VPC_NAT_Instance.html
// https://dzone.com/articles/nat-instance-vs-nat-gateway

# If something changes here, you might need this: `tg taint module.subnets.aws_instance.nat_instance[0]` to force a recreate (run for each subnet replacing 0)
// Include our temporary security group here
resource "aws_launch_configuration" "nat_instance" {
  name_prefix          = module.nat_label.id
  image_id             = data.aws_ami.nat_instance.id
  instance_type        = var.nat_instance_type
  iam_instance_profile = var.instance_profile
  key_name             = var.bastion_service_host_key_name
  security_groups      = [aws_security_group.nat_instance[0].id, aws_security_group.bastion_service.id]
  user_data_base64     = data.template_cloudinit_config.config.rendered
  root_block_device {
    encrypted = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

//Get the subnet AZ's in order
data "aws_subnet" "selected" {
  count = var.enabled ? local.nat_instance_count : 0
  id    = element(aws_subnet.public.*.id, count.index)
}

resource "random_id" "cfn_stack" {
  keepers = {
    # Generate a new id each time we replace the launch config
    stack_id = aws_launch_configuration.nat_instance.id
  }

  byte_length = 8
}

// This is a hack that allows us to do zero-downtime redeployments of NAT instances: https://medium.com/@endofcake/using-terraform-for-zero-downtime-updates-of-an-auto-scaling-group-in-aws-60faca582664
resource "aws_cloudformation_stack" "autoscaling_group" {
  count            = var.enabled ? local.nat_instance_count : 0
  name             = "${format("%s%s%s", module.nat_label.id, var.delimiter, replace(element(var.availability_zones, count.index), "-", var.delimiter))}-${random_id.cfn_stack.dec}"
  disable_rollback = true

  template_body = <<EOF
Description: "Autoscaling group for NAT instances in subnet ${element(aws_subnet.public.*.id, count.index)}."
Resources:
  ASG:
    Type: AWS::AutoScaling::AutoScalingGroup
    Properties:
      VPCZoneIdentifier: ["${element(aws_subnet.public.*.id, count.index)}"]
      AvailabilityZones: ["${element(data.aws_subnet.selected.*.availability_zone, count.index)}"]
      LaunchConfigurationName: "${aws_launch_configuration.nat_instance.name}"
      MinSize: "0"
      MaxSize: "2"
      DesiredCapacity: "1"
      HealthCheckType: EC2
      Tags:
        - Key: Name
          Value: "${format("%s%s%s", module.nat_label.id, var.delimiter, replace(element(var.availability_zones, count.index), "-", var.delimiter))}"
          PropagateAtLaunch: "true"
        - Key: eip
          Value: "${element(aws_eip.nat_instance.*.id, count.index)}"
          PropagateAtLaunch: "true"
        - Key: route_table
          Value: "${element(aws_route_table.private.*.id, count.index)}"
          PropagateAtLaunch: "true"

    CreationPolicy:
      AutoScalingCreationPolicy:
        MinSuccessfulInstancesPercent: 80
      ResourceSignal:
        Count: "1"
        Timeout: PT10M
    UpdatePolicy:
    # Ignore differences in group size properties caused by scheduled actions
      AutoScalingScheduledAction:
        IgnoreUnmodifiedGroupSizeProperties: true
      AutoScalingRollingUpdate:
        MaxBatchSize: "1"
        MinInstancesInService: "1"
        MinSuccessfulInstancesPercent: 80
        PauseTime: PT10M
        SuspendProcesses:
          - HealthCheck
          - ReplaceUnhealthy
          - AZRebalance
          - AlarmNotification
          - ScheduledActions
        WaitOnResourceSignals: true
    #DeletionPolicy: Retain
Outputs:
  NatGatewayASG:
    Description: ID for the NAT Gateway autoscaling group
    Value: !Ref ASG
    Export:
      Name: ${var.prefix_alphanum}-NatGateway-${element(var.availability_zones, count.index)}-${random_id.cfn_stack.dec}
  EOF

  lifecycle {
    create_before_destroy = true
  }

  metadata_options {
    http_endpoint               = (var.metadata_http_endpoint_enabled) ? "enabled" : "disabled"
    http_put_response_hop_limit = var.metadata_http_put_response_hop_limit
    http_tokens                 = (var.metadata_http_tokens_required) ? "required" : "optional"
  }

  root_block_device {
    encrypted = var.root_block_device_encrypted
  }
}

# resource "aws_instance" "nat_instance" {
#   count                  = var.enabled ? local.nat_instance_count : 0
#   ami                    = join("", data.aws_ami.nat_instance.*.id)
#   instance_type          = var.nat_instance_type
#   subnet_id              = element(aws_subnet.public.*.id, count.index)
#   vpc_security_group_ids = [aws_security_group.nat_instance[0].id, aws_security_group.bastion_service.id]
#   iam_instance_profile = aws_iam_instance_profile.bastion_service_profile.name

#   user_data = data.template_cloudinit_config.config.rendered
#   key_name = var.bastion_service_host_key_name

#   # credit_specification = {
#   #   cpu_credits = "standard" # Not sure why this doesn't work?
#   # }

#   // This makes TF not continue unless the instance is up
#   provisioner "remote-exec" {
#       inline = [
#         "/bin/bash -c \"timeout 300 sed '/finished-user-data/q' <(tail -f /var/log/cloud-init-output.log)\""
#       ]
#   }

#   tags = merge(
#     module.nat_instance_label.tags,
#     {
#       "Name" = format(
#         "%s%s%s",
#         module.nat_label.id,
#         var.delimiter,
#         replace(
#           element(var.availability_zones, count.index),
#           "-",
#           var.delimiter
#         )
#       )
#     }
#   )

#   # Required by NAT
#   # https://docs.aws.amazon.com/vpc/latest/userguide/VPC_NAT_Instance.html#EIP_Disable_SrcDestCheck
#   source_dest_check = false

#   associate_public_ip_address = true

#   lifecycle {
#     create_before_destroy = true
#   }
# }

resource "aws_eip" "nat_instance" {
  count = local.enabled ? local.nat_instance_eip_count : 0
  vpc   = true
  tags = merge(
    module.nat_instance_label.tags,
    {
      "Name" = format("%s%s%s", module.nat_instance_label.id, local.delimiter, local.az_map[element(var.availability_zones, count.index)])
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# resource "aws_eip_association" "nat_instance" {
#   count         = var.enabled ? local.nat_instance_count : 0
#   instance_id   = element(aws_instance.nat_instance.*.id, count.index)
#   allocation_id = element(local.instance_eip_allocations, count.index)
# }

# resource "aws_route" "nat_instance" {
#   count                  = var.enabled ? local.nat_instance_count : 0
#   route_table_id         = element(aws_route_table.private.*.id, count.index)
#   instance_id            = element(aws_instance.nat_instance.*.id, count.index)
#   destination_cidr_block = "0.0.0.0/0"
#   depends_on             = [aws_route_table.private]

#   timeouts {
#     create = var.aws_route_create_timeout
#     delete = var.aws_route_delete_timeout
#   }
# }

// Since this script will make new bastions but not delete the old ones by default (Due to a bug here: https://github.com/terraform-providers/terraform-provider-aws/issues/5011), we need to nuke the old bastions manually
// Identify them by their tag "nat-instance" and the fact they have no elastic ipv4 attached
# resource "null_resource" "nuke_old_bastions" {

# }
