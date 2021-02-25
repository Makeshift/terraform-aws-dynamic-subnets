## Requirements

| Name | Version |
|------|---------|
| terraform | >= 0.12.0, < 0.14.0 |
| aws | ~> 2.0 |
| local | ~> 1.2 |
| null | ~> 2.0 |
| random | ~> 2.3.0 |
| template | ~> 2.0 |

## Providers

| Name | Version |
|------|---------|
| aws | ~> 2.0 |
| random | ~> 2.3.0 |
| template | ~> 2.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| additional\_tag\_map | Additional tags for appending to each tag map | `map(string)` | `{}` | no |
| assume\_role\_arn | arn for role to assume in separate identity account if used | `string` | `""` | no |
| attributes | Any extra attributes for naming these resources | `list(string)` | `[]` | no |
| availability\_zones | List of Availability Zones where subnets will be created | `list(string)` | n/a | yes |
| aws\_route\_create\_timeout | Time to wait for AWS route creation specifed as a Go Duration, e.g. `2m` | `string` | `"2m"` | no |
| aws\_route\_delete\_timeout | Time to wait for AWS route deletion specifed as a Go Duration, e.g. `5m` | `string` | `"5m"` | no |
| bastion\_allowed\_iam\_group | Name IAM group, members of this group will be able to ssh into bastion instances if they have provided ssh key in their profile | `string` | `""` | no |
| bastion\_assume\_role\_arn | arn for role to assume in separate identity account if used | `string` | `""` | no |
| bastion\_cidr\_blocks\_whitelist\_host | range(s) of incoming IP addresses to whitelist for the HOST | `list(string)` | <pre>[<br>  "127.0.0.1/32"<br>]</pre> | no |
| bastion\_cidr\_blocks\_whitelist\_service | range(s) of incoming IP addresses to whitelist for the SERVICE | `list(string)` | <pre>[<br>  "127.0.0.1/32"<br>]</pre> | no |
| bastion\_custom\_authorized\_keys\_command | any value excludes default Go binary iam-authorized-keys built from source from userdata | `string` | `""` | no |
| bastion\_custom\_docker\_setup | any value excludes default docker installation and container build from userdata | `string` | `""` | no |
| bastion\_custom\_ssh\_populate | any value excludes default ssh\_populate script used on container launch from userdata | `string` | `""` | no |
| bastion\_custom\_systemd | any value excludes default systemd and hostname change from userdata | `string` | `""` | no |
| bastion\_service\_host\_key\_name | AWS ssh key \*.pem to be used for ssh access to the bastion service host | `string` | `""` | no |
| cidr\_block | Base CIDR block which will be divided into subnet CIDR blocks (e.g. `10.0.0.0/16`) | `string` | n/a | yes |
| context | Default context to use for passing state between label invocations | <pre>object({<br>    namespace           = string<br>    environment         = string<br>    stage               = string<br>    name                = string<br>    enabled             = bool<br>    delimiter           = string<br>    attributes          = list(string)<br>    label_order         = list(string)<br>    tags                = map(string)<br>    additional_tag_map  = map(string)<br>    regex_replace_chars = string<br>  })</pre> | <pre>{<br>  "additional_tag_map": {},<br>  "attributes": [],<br>  "delimiter": "",<br>  "enabled": true,<br>  "environment": "",<br>  "label_order": [],<br>  "name": "",<br>  "namespace": "",<br>  "regex_replace_chars": "",<br>  "stage": "",<br>  "tags": {}<br>}</pre> | no |
| delimiter | Delimiter to be used between `namespace`, `stage`, `name` and `attributes` | `string` | `"-"` | no |
| enabled | Set to false to prevent the module from creating any resources | `bool` | `true` | no |
| environment | The environment name if not using stage | `string` | `""` | no |
| existing\_nat\_ips | Existing Elastic IPs to attach to the NAT Gateway or Instance instead of creating a new one. | `list(string)` | `[]` | no |
| extra\_user\_data\_content | Extra user-data to add to the default built-in | `string` | `""` | no |
| extra\_user\_data\_content\_type | What format is content in - eg 'text/cloud-config' or 'text/x-shellscript' | `string` | `"text/x-shellscript"` | no |
| extra\_user\_data\_merge\_type | Control how cloud-init merges user-data sections | `string` | `"str(append)"` | no |
| igw\_id | Internet Gateway ID the public route table will point to (e.g. `igw-9c26a123`) | `string` | n/a | yes |
| instance\_profile | The profile the instance should use to get information | `string` | n/a | yes |
| label\_order | The naming order of the ID output and Name tag | `list(string)` | `[]` | no |
| map\_public\_ip\_on\_launch | Instances launched into a public subnet should be assigned a public IP address | `bool` | `true` | no |
| max\_subnet\_count | Sets the maximum amount of subnets to deploy. 0 will deploy a subnet for every provided availablility zone (in `availability_zones` variable) within the region | `number` | `0` | no |
| name | Solution name, e.g. 'app' or 'cluster' | `string` | `""` | no |
| namespace | Namespace, which could be your organization name or abbreviation, e.g. 'eg' or 'cp' | `string` | `""` | no |
| nat\_gateway\_enabled | Flag to enable/disable NAT Gateways to allow servers in the private subnets to access the Internet | `bool` | `true` | no |
| nat\_instance\_enabled | Flag to enable/disable NAT Instances to allow servers in the private subnets to access the Internet | `bool` | `false` | no |
| nat\_instance\_type | NAT Instance type | `string` | `"t3.micro"` | no |
| prefix\_alphanum | n/a | `string` | n/a | yes |
| private\_network\_acl\_id | Network ACL ID that will be added to private subnets. If empty, a new ACL will be created | `string` | `""` | no |
| private\_subnets\_additional\_tags | Additional tags to be added to private subnets | `map(string)` | `{}` | no |
| public\_network\_acl\_id | Network ACL ID that will be added to public subnets. If empty, a new ACL will be created | `string` | `""` | no |
| public\_subnets\_additional\_tags | Additional tags to be added to public subnets | `map(string)` | `{}` | no |
| regex\_replace\_chars | Regex to replace chars with empty string in `namespace`, `environment`, `stage` and `name`. By default only hyphens, letters and digits are allowed, all other chars are removed | `string` | `"/[^a-zA-Z0-9-]/"` | no |
| region | What region are we in? | `string` | n/a | yes |
| stage | Stage, e.g. 'prod', 'staging', 'dev', or 'test' | `string` | `""` | no |
| subnet\_type\_tag\_key | Key for subnet type tag to provide information about the type of subnets, e.g. `cpco.io/subnet/type=private` or `cpco.io/subnet/type=public` | `string` | `"cpco.io/subnet/type"` | no |
| subnet\_type\_tag\_value\_format | This is using the format interpolation symbols to allow the value of the subnet\_type\_tag\_key to be modified. | `string` | `"%s"` | no |
| tags | Additional tags to apply to all resources that use this label module | `map(string)` | `{}` | no |
| vpc\_default\_route\_table\_id | Default route table for public subnets. If not set, will be created. (e.g. `rtb-f4f0ce12`) | `string` | `""` | no |
| vpc\_id | VPC ID where subnets will be created (e.g. `vpc-aceb2723`) | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| availability\_zones | List of Availability Zones where subnets were created |
| nat\_gateway\_ids | IDs of the NAT Gateways created |
| nat\_instance\_asg\_cfn\_ids | The Cloudformation stacks that contain the NAT Gateway auto-scaling groups |
| nat\_instance\_ips | List of Bastion IPs |
| private\_route\_table\_ids | IDs of the created private route tables |
| private\_subnet\_cidrs | CIDR blocks of the created private subnets |
| private\_subnet\_ids | IDs of the created private subnets |
| public\_route\_table\_ids | IDs of the created public route tables |
| public\_subnet\_cidrs | CIDR blocks of the created public subnets |
| public\_subnet\_ids | IDs of the created public subnets |
