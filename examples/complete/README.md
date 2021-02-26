## Requirements

No requirements.

## Providers

No provider.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| availability\_zones | List of Availability Zones where subnets will be created | `list(string)` | n/a | yes |
| name | Solution/application name, e.g. 'app' or 'cluster' | `string` | n/a | yes |
| namespace | Namespace, which could be your organization name or abbreviation, e.g. 'eg' or 'cp' | `string` | n/a | yes |
| region | AWS region | `string` | n/a | yes |
| stage | Stage, e.g. 'prod', 'staging', 'dev', or 'test' | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| private\_subnet\_cidrs | n/a |
| public\_subnet\_cidrs | n/a |
