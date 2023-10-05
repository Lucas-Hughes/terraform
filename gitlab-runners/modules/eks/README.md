<!-- BEGIN_TF_DOCS -->

  This module is designed to create GitLab runner executors in EKS.

  # GitLab Runner on EKS with Docker Exectuors

This repository contains a Terraform module for deploying a self-managed GitLab Runner on an EKS instance with a Docker executor.

By default, this will only have the SSM core role and other necessary, minimalistic policies. You will need to add the permissions to meet the "least permissive" policy. See the `additional_policies` under Step 1.

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Known Issues](#known-issues)
- [Usage](#usage)
  - [Step 1: Optional - Complete the prerequisite requirements](#step-1-optional-if-completed-previously-prerequisites)
  - [Step 2: Use the Correct Source Block for this Terraform Module](#step-2-use-the-correct-source-block-for-this-terraform-module)
  - [Step 3: Create a GitLab Runner Manager](#step-3-create-a-gitlab-runner-manager)
  - [Step 4: Update the configuration file with your token](#step-4-update-the-configuration)
  - [Step 5: Deploy the GitLab Runner](#step-5-deploy-the-gitlab-runner)
- [Documentation](#documentation)
- [Support](#support)

## Overview

The GitLab Runner is responsible for executing CI/CD jobs defined in your GitLab projects. The runner lives in GitLab and utilizes Docker containers on the instances to execute jobs.

## Prerequisites

To use this repository, you need the following:

- AWS account with appropriate permissions
- [Terraform](https://www.terraform.io/downloads.html) installed (version 1.5.0 or later)
- [Git](https://git-scm.com/downloads) installed
- At least reporter permissions in GitLab
- A personal access token created in GitLab and added to your ~/.terraformrc (see step 1 below)
- A KMS grant created in your account to utilize PCM images in autoscaling groups

## Known Issues

- When using the EKS module to create more than one eks cluster in the same account, coredns may fail to install after 20 minutes. This does not prevent the runner from working, but the terraform resource will fail to create.

## Usage

Follow these steps to deploy the GitLab Runner on your AWS infrastructure:

### Step 1 (Optional if completed previously): Prerequisites

## Create a GitLab personal access token and add to ~/.terraformrc

To access the private terraform module registry from your local machine, you will need to authenticate to that registry using the personal access token created in the GitLab console.

Click on your profile image -> edit profile -> Access Tokens -> Add New Token -> Create a token with api and read\_api permissions.

Once the token value is generated, grab that token and place it in your ~/.terraformrc file using the following echo command. You can also place the token value using the text editor of your choice. If you do not have a a ~/.terraformrc, please create one.

`echo 'credentials "gitlab.com" {token = "glpat-yourtokenvalue"}' >> ~/.terraformrc`

This token will now allow us to run `terraform init` and pull the module into our local machine.

## Create a KMS grant to PCM master account to utilize their AMIs in autoscaling groups

Because the AMIs that are utilized in this module are created by PCM, we must have a grant in their account to decrypt their EBS volumes. All we need to do is run the following command in the account you're wanting to deploy the runner to, replacing `<your_account_id>` with the account ID:

`aws kms create-grant --region us-east-1 --key-id arn:aws:kms:us-east-1:056952386373:key/0f0224cd-e20a-4011-bb5e-6bead7fb9747 --grantee-principal arn:aws:iam::<your_account_id>:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling --operations "Encrypt" "Decrypt" "ReEncryptFrom" "ReEncryptTo" "GenerateDataKey" "GenerateDataKeyWithoutPlaintext" "DescribeKey" "CreateGrant"`

### Step 2: Copy the module block from below to the terraform main.tf you want to deploy the runners from.

Please note that you must provide either the property `vpc_cidr_block` which will create a new vpc to host the runner or `private_subnets` which will create the runner in already existing private subnet(s).

```hcl
module "eks_gitlab_runner" {
  source  = ""
  version = "latest" # needs to be a specific version

    enable_schedules    = true

    gitlab_runner_token = <use_this_in_terraform.tfvars> # don't put tokens in plaintext!
    project_name        = "forge-eks-gitlab-runner"
    vpc_cidr_block      = "132.0.0.0/16"
    environment         = "DEMO"

    tags = {
        "t_AppID" = "SVC03377"
        "t_dcl"   = "3"
        "Owner"   = "lucas.j.hughes@outlook.com"
    }

    additional_policies = {
        "additional_policy" = "arn:aws:iam::aws:policy/job-function/SystemAdministrator"
    } # this is a map of policies to merge with SSM. Can put as many in this block as needed
}
```

If you are still unsure what a complete main.tf to deploy the runner should look like, please look at the ./examples/ directory to see a working example of the module being called. Please note that the source block will look different.

### Step 3: Create a GitLab Runner Manager

Due to token architecture changes, you need to create the GitLab runner manager inside the GitLab console and get a token from there.

- If you are working at the group level, navigate to `group -> build -> runners -> New Group Runner`, create a new runner, and grab the token.
- If you are working at the project level, navigate to `settings -> CI/CD -> runners -> New Project Runner`, create a new runner, and grab the token.

Remember, you need to have maintainer/owner permissions in GitLab to perform these actions.

### Step 4: Update the Configuration

1. Update the `terraform.tfvars` file with your gitlab runner token you created in step 2.

    - gitlab\_runner\_token = "glrt-xxxxxxxxxxxxxxx"

### Step 5: Deploy the GitLab Runner

1. Initialize the Terraform backend and download the required providers:

    ```bash
    terraform init
    ```

2. (Optional) Review the Terraform plan:

    ```bash
    terraform plan
    ```

3. Apply the Terraform configuration to deploy the GitLab Runner:

    ```bash
    terraform apply
    yes
    ```

## Documentation

For more information about GitLab Runners, Docker, and Terraform, refer to the following documentation:

- [GitLab Runner documentation](https://docs.gitlab.com/runner/)
- [Docker documentation](https://docs.docker.com/)
- [Terraform documentation](https://www.terraform.io/docs/index.html)

## Support

If you encounter any issues or have questions about this GitLab Runner configuration, please open an issue in this repository, or contact your organization's support team.

#### Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.0 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | >= 2.9 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | >= 2.20 |

#### Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 5.0 |

#### Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_eks"></a> [eks](#module\_eks) | terraform-aws-modules/eks/aws | ~> 19.0 |
| <a name="module_vpc"></a> [vpc](#module\_vpc) | terraform-aws-modules/vpc/aws | ~> 5.0 |

#### Resources

| Name | Type |
|------|------|
| [aws_ami.pcm_eks_ami](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_availability_zones.available](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zones) | data source |
| [aws_subnet.existing](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnet) | data source |

#### Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_gitlab_runner_token"></a> [gitlab\_runner\_token](#input\_gitlab\_runner\_token) | GitLab Runner Token | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Common tags for all resources | `map(string)` | n/a | yes |
| <a name="input_additional_policies"></a> [additional\_policies](#input\_additional\_policies) | Additional IAM policies to be merged. Format is whatever\_name = arn\_of\_policy. | `map(string)` | `{}` | no |
| <a name="input_capacity_type"></a> [capacity\_type](#input\_capacity\_type) | Type of capacity associated with the EKS Node Group. Valid values: ON\_DEMAND, SPOT. Terraform will only perform drift detection if a configuration value is provided. | `string` | `"SPOT"` | no |
| <a name="input_cluster_version"></a> [cluster\_version](#input\_cluster\_version) | Version of Kubernetes to use in the EKS cluster | `string` | `"1.27"` | no |
| <a name="input_concurrency"></a> [concurrency](#input\_concurrency) | The amount of jobs you want to run concurrently - https://docs.gitlab.com/runner/configuration/advanced-configuration.html | `number` | `10` | no |
| <a name="input_docker_runner_image"></a> [docker\_runner\_image](#input\_docker\_runner\_image) | The image to run jobs with inside the container | `string` | `"alpine:latest"` | no |
| <a name="input_ecr_region"></a> [ecr\_region](#input\_ecr\_region) | The AWS region of the ECR repository. Defaults to '' | `string` | `""` | no |
| <a name="input_ecr_uri"></a> [ecr\_uri](#input\_ecr\_uri) | The URI of the ECR image that you're wanting to authenticate to | `string` | `""` | no |
| <a name="input_enable_schedules"></a> [enable\_schedules](#input\_enable\_schedules) | Enable or disable scheduling for EKS | `bool` | `false` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment you're working in | `string` | `"DEV"` | no |
| <a name="input_instance_types"></a> [instance\_types](#input\_instance\_types) | List of instance types. | `list(string)` | <pre>[<br>  "t3.medium",<br>  "t3.large"<br>]</pre> | no |
| <a name="input_private_subnets"></a> [private\_subnets](#input\_private\_subnets) | List of private subnets where the GitLab runner will be deployed. | `list(string)` | `null` | no |
| <a name="input_privileged"></a> [privileged](#input\_privileged) | Allows the docker containers to run in privileged mode. Necessary for DinD. Please note that this is insecure and should only be used if using DinD | `bool` | `false` | no |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Prefix of the project that will be used throughout the deployment | `string` | `""` | no |
| <a name="input_region"></a> [region](#input\_region) | AWS Region | `string` | `"us-east-1"` | no |
| <a name="input_runner_asg_desired_size"></a> [runner\_asg\_desired\_size](#input\_runner\_asg\_desired\_size) | Desired number of instances you want running in the runner ASG. Module has this in ignore\_changes. May need to recreate or use enable\_schedules to change this. | `number` | `2` | no |
| <a name="input_runner_asg_max_size"></a> [runner\_asg\_max\_size](#input\_runner\_asg\_max\_size) | Max number of instances you want running in the runner ASG | `number` | `7` | no |
| <a name="input_runner_asg_min_size"></a> [runner\_asg\_min\_size](#input\_runner\_asg\_min\_size) | Minimum number of instances you want running in the runner ASG | `number` | `0` | no |
| <a name="input_runner_kms_key"></a> [runner\_kms\_key](#input\_runner\_kms\_key) | Customer Managed Key for encrypting EBS volumes on the runner. Defaults to AWS managed key | `string` | `null` | no |
| <a name="input_runner_volume_size"></a> [runner\_volume\_size](#input\_runner\_volume\_size) | The volume size of the runner in GB | `number` | `30` | no |
| <a name="input_scale_down_cron"></a> [scale\_down\_cron](#input\_scale\_down\_cron) | Cron expression for scaling down. Defaults to 8am EDT/7am EST Mon-Fri | `string` | `"0 0 * * TUE-SAT"` | no |
| <a name="input_scale_down_desired"></a> [scale\_down\_desired](#input\_scale\_down\_desired) | The desired number of instances allowed when the asg scales down. | `number` | `0` | no |
| <a name="input_scale_down_maximum"></a> [scale\_down\_maximum](#input\_scale\_down\_maximum) | The maximum number of instances allowed when the asg scales down. | `number` | `3` | no |
| <a name="input_scale_down_minimum"></a> [scale\_down\_minimum](#input\_scale\_down\_minimum) | The minimum number of instances allowed when the asg scales down. | `number` | `0` | no |
| <a name="input_scale_up_cron"></a> [scale\_up\_cron](#input\_scale\_up\_cron) | Cron expression for scaling up. Defaults to 8am EDT/7am EST Mon-Fri | `string` | `"0 12 * * MON-FRI"` | no |
| <a name="input_scale_up_desired"></a> [scale\_up\_desired](#input\_scale\_up\_desired) | The desired number of instances allowed when the asg scales up. | `number` | `2` | no |
| <a name="input_scale_up_maximum"></a> [scale\_up\_maximum](#input\_scale\_up\_maximum) | The maximum number of instances allowed when the asg scales up. | `number` | `7` | no |
| <a name="input_scale_up_minimum"></a> [scale\_up\_minimum](#input\_scale\_up\_minimum) | The minimum number of instances allowed when the asg scales up. | `number` | `2` | no |
| <a name="input_vpc_cidr_block"></a> [vpc\_cidr\_block](#input\_vpc\_cidr\_block) | VPC CIDR block | `string` | `null` | no |

#### Outputs

| Name | Description |
|------|-------------|
| <a name="output_aws_auth_configmap_yaml"></a> [aws\_auth\_configmap\_yaml](#output\_aws\_auth\_configmap\_yaml) | Formatted yaml output for base aws-auth configmap containing roles used in cluster node groups/fargate profiles |
| <a name="output_cloudwatch_log_group_arn"></a> [cloudwatch\_log\_group\_arn](#output\_cloudwatch\_log\_group\_arn) | Arn of cloudwatch log group created |
| <a name="output_cloudwatch_log_group_name"></a> [cloudwatch\_log\_group\_name](#output\_cloudwatch\_log\_group\_name) | Name of cloudwatch log group created |
| <a name="output_cluster_addons"></a> [cluster\_addons](#output\_cluster\_addons) | Map of attribute maps for all EKS cluster addons enabled |
| <a name="output_cluster_arn"></a> [cluster\_arn](#output\_cluster\_arn) | The Amazon Resource Name (ARN) of the cluster |
| <a name="output_cluster_certificate_authority_data"></a> [cluster\_certificate\_authority\_data](#output\_cluster\_certificate\_authority\_data) | Base64 encoded certificate data required to communicate with the cluster |
| <a name="output_cluster_endpoint"></a> [cluster\_endpoint](#output\_cluster\_endpoint) | Endpoint for your Kubernetes API server |
| <a name="output_cluster_iam_role_arn"></a> [cluster\_iam\_role\_arn](#output\_cluster\_iam\_role\_arn) | IAM role ARN of the EKS cluster |
| <a name="output_cluster_iam_role_name"></a> [cluster\_iam\_role\_name](#output\_cluster\_iam\_role\_name) | IAM role name of the EKS cluster |
| <a name="output_cluster_iam_role_unique_id"></a> [cluster\_iam\_role\_unique\_id](#output\_cluster\_iam\_role\_unique\_id) | Stable and unique string identifying the IAM role |
| <a name="output_cluster_id"></a> [cluster\_id](#output\_cluster\_id) | The ID of the EKS cluster. Note: currently a value is returned only for local EKS clusters created on Outposts |
| <a name="output_cluster_identity_providers"></a> [cluster\_identity\_providers](#output\_cluster\_identity\_providers) | Map of attribute maps for all EKS identity providers enabled |
| <a name="output_cluster_name"></a> [cluster\_name](#output\_cluster\_name) | The name of the EKS cluster |
| <a name="output_cluster_oidc_issuer_url"></a> [cluster\_oidc\_issuer\_url](#output\_cluster\_oidc\_issuer\_url) | The URL on the EKS cluster for the OpenID Connect identity provider |
| <a name="output_cluster_platform_version"></a> [cluster\_platform\_version](#output\_cluster\_platform\_version) | Platform version for the cluster |
| <a name="output_cluster_primary_security_group_id"></a> [cluster\_primary\_security\_group\_id](#output\_cluster\_primary\_security\_group\_id) | Cluster security group that was created by Amazon EKS for the cluster. Managed node groups use this security group for control-plane-to-data-plane communication. Referred to as 'Cluster security group' in the EKS console |
| <a name="output_cluster_security_group_arn"></a> [cluster\_security\_group\_arn](#output\_cluster\_security\_group\_arn) | Amazon Resource Name (ARN) of the cluster security group |
| <a name="output_cluster_security_group_id"></a> [cluster\_security\_group\_id](#output\_cluster\_security\_group\_id) | ID of the cluster security group |
| <a name="output_cluster_status"></a> [cluster\_status](#output\_cluster\_status) | Status of the EKS cluster. One of `CREATING`, `ACTIVE`, `DELETING`, `FAILED` |
| <a name="output_cluster_tls_certificate_sha1_fingerprint"></a> [cluster\_tls\_certificate\_sha1\_fingerprint](#output\_cluster\_tls\_certificate\_sha1\_fingerprint) | The SHA1 fingerprint of the public key of the cluster's certificate |
| <a name="output_eks_managed_node_groups"></a> [eks\_managed\_node\_groups](#output\_eks\_managed\_node\_groups) | Map of attribute maps for all EKS managed node groups created |
| <a name="output_eks_managed_node_groups_autoscaling_group_names"></a> [eks\_managed\_node\_groups\_autoscaling\_group\_names](#output\_eks\_managed\_node\_groups\_autoscaling\_group\_names) | List of the autoscaling group names created by EKS managed node groups |
| <a name="output_fargate_profiles"></a> [fargate\_profiles](#output\_fargate\_profiles) | Map of attribute maps for all EKS Fargate Profiles created |
| <a name="output_kms_key_arn"></a> [kms\_key\_arn](#output\_kms\_key\_arn) | The Amazon Resource Name (ARN) of the key |
| <a name="output_kms_key_id"></a> [kms\_key\_id](#output\_kms\_key\_id) | The globally unique identifier for the key |
| <a name="output_kms_key_policy"></a> [kms\_key\_policy](#output\_kms\_key\_policy) | The IAM resource policy set on the key |
| <a name="output_node_security_group_arn"></a> [node\_security\_group\_arn](#output\_node\_security\_group\_arn) | Amazon Resource Name (ARN) of the node shared security group |
| <a name="output_node_security_group_id"></a> [node\_security\_group\_id](#output\_node\_security\_group\_id) | ID of the node shared security group |
| <a name="output_oidc_provider"></a> [oidc\_provider](#output\_oidc\_provider) | The OpenID Connect identity provider (issuer URL without leading `https://`) |
| <a name="output_oidc_provider_arn"></a> [oidc\_provider\_arn](#output\_oidc\_provider\_arn) | The ARN of the OIDC Provider if `enable_irsa = true` |
| <a name="output_private_subnets"></a> [private\_subnets](#output\_private\_subnets) | List of IDs of private subnets |
| <a name="output_self_managed_node_groups"></a> [self\_managed\_node\_groups](#output\_self\_managed\_node\_groups) | Map of attribute maps for all self managed node groups created |
| <a name="output_self_managed_node_groups_autoscaling_group_names"></a> [self\_managed\_node\_groups\_autoscaling\_group\_names](#output\_self\_managed\_node\_groups\_autoscaling\_group\_names) | List of the autoscaling group names created by self-managed node groups |

<!-- END_TF_DOCS -->