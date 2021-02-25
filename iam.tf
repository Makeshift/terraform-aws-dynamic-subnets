#aws iam role for host -same account queries

# resource "aws_iam_role" "bastion_service_role" {
#   name = "${module.nat_instance_label.id}-bastion-service"
#   count              = local.assume_role_no
#   assume_role_policy = data.aws_iam_policy_document.bastion_service_role_assume[0].json
#   tags               = var.tags
# }

# data "aws_iam_policy_document" "bastion_service_role_assume" {
#   count = local.assume_role_no

#   statement {
#     actions = [
#       "sts:AssumeRole",
#     ]

#     principals {
#       type = "Service"

#       identifiers = [
#         "ec2.amazonaws.com",
#       ]
#     }
#   }
# }

# #########################
# #Instance profile to assume role
# #########################

# resource "aws_iam_instance_profile" "bastion_service_profile" {
#   name = "${module.nat_instance_label.id}-bastion-service"

#   role = aws_iam_role.bastion_service_role[0].name
# }

# data "aws_iam_policy_document" "check_ssh_authorized_keys" {
#   count = local.assume_role_no

#   statement {
#     effect = "Allow"

#     actions = [
#       "iam:ListUsers",
#       "iam:GetGroup",
#       "iam:GetSSHPublicKey",
#       "iam:ListSSHPublicKeys",
#       "iam:GetUser",
#       "iam:ListGroups",
#       "ec2:DescribeTags",
#     ]

#     resources = [
#       "*",
#     ]
#   }


# }

# resource "aws_iam_policy" "check_ssh_authorized_keys" {
#   name = "${module.nat_instance_label.id}-bastion-service"
#   count  = local.assume_role_no
#   policy = data.aws_iam_policy_document.check_ssh_authorized_keys[0].json
# }

# resource "aws_iam_role_policy_attachment" "check_ssh_authorized_keys" {
#   role       = aws_iam_role.bastion_service_role[0].name
#   count      = local.assume_role_no
#   policy_arn = aws_iam_policy.check_ssh_authorized_keys[0].arn
# }
