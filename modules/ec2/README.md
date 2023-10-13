<!-- BEGIN_TF_DOCS -->

<!-- BEGIN\_TF\_DOCS -->

This module is designed to create GitLab runner executors in EC2.

# GitLab Runner on EC2 with Docker Exectuors

This repository contains a Terraform module for deploying a self-managed GitLab Runner on an EC2 instance with a Docker executor.

By default, this will only have the SSM core role and other necessary, minimalistic policies. You will need to add the permissions to meet the "least permissive" policy. See the `additional_policies` under Step 1.

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
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

## Usage

Follow these steps to deploy the GitLab Runner on your AWS infrastructure:

### Step 1 (Optional if completed previously): Prerequisites

- Install Terraform
- Have a GitLab account

### Step 2: Copy the module block from below to the terraform main.tf you want to deploy the runners from.

Please note that you must provide either the property `vpc_cidr_block` which will create a new vpc to host the runner or `private_subnets` which will create the runner in already existing private subnet(s).

To find the version number, use the drop down for branch and find the latest `tag`. It will look like 1.0.0

```hcl
module "ec2_gitlab_runner" {
  source  = "Lucas-Hughes/gitlab-runner/aws//modules/ec2"
  version = "1.0.0"

  gitlab_runner_token = var.gitlab_runner_token # put this in a terraform.tfvars and do not commit it to VCS!
  project_name        = "gitlab-runner"
  vpc_cidr_block      = "145.0.0.0/24"
  environment         = "DEMO"

  tags = {
    "Owner"   = "lucas.j.hughes@outlook.com"
    "Project" = "GitLab.Runner
  }

  additional_policies = {
    "additional_policy" = "arn:aws:iam::aws:policy/job-function/SystemAdministrator"
  }
}
```

If you are still unsure what a complete main.tf to deploy the runner should look like, please look at the ./examples/ directory to see a working example of the module being called. Please note that the source block will look different.

### Step 3: Create a GitLab Runner

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
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5, < 2.0.0 |
| <a name="requirement_archive"></a> [archive](#requirement\_archive) | ~> 2.4 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.0 |

#### Providers

| Name | Version |
|------|---------|
| <a name="provider_archive"></a> [archive](#provider\_archive) | ~> 2.4 |
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 5.0 |

#### Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_vpc"></a> [vpc](#module\_vpc) | terraform-aws-modules/vpc/aws | ~> 5.0 |

#### Resources

| Name | Type |
|------|------|
| [aws_autoscaling_group.runner_asg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group) | resource |
| [aws_cloudwatch_event_rule.ami_eventbridge_rule](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_rule) | resource |
| [aws_cloudwatch_event_target.ami_eventbridge_rule_target](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target) | resource |
| [aws_iam_instance_profile.runner_instance_profile](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile) | resource |
| [aws_iam_policy.lambda_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.lambda_execution_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.runner_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.lambda_role_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.merged_policies](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_lambda_function.runner_ami_update](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function) | resource |
| [aws_lambda_permission.runner_ami_update_permission](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission) | resource |
| [aws_launch_template.gitlab_runner](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_template) | resource |
| [aws_security_group.gitlab_runner_sg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [archive_file.lambda](https://registry.terraform.io/providers/hashicorp/archive/latest/docs/data-sources/file) | data source |
| [aws_ami.latest_amazon_linux](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_availability_zones.available](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zones) | data source |
| [aws_subnet.existing](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnet) | data source |

#### Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_gitlab_runner_token"></a> [gitlab\_runner\_token](#input\_gitlab\_runner\_token) | GitLab Runner Token | `string` | n/a | yes |
| <a name="input_additional_policies"></a> [additional\_policies](#input\_additional\_policies) | Additional IAM policies to be merged. Format is whatever\_name = arn\_of\_policy. | `map(string)` | `{}` | no |
| <a name="input_concurrency"></a> [concurrency](#input\_concurrency) | The amount of jobs you want to run concurrently - https://docs.gitlab.com/runner/configuration/advanced-configuration.html | `number` | `15` | no |
| <a name="input_custom_runner_ami"></a> [custom\_runner\_ami](#input\_custom\_runner\_ami) | Custom AMI to be used in the GitLab runner. If left blank, it will source the PCM Amazon Linux 2 image | `string` | `""` | no |
| <a name="input_docker_runner_image"></a> [docker\_runner\_image](#input\_docker\_runner\_image) | The image to run jobs with inside the container | `string` | `"alpine:latest"` | no |
| <a name="input_ebs_kms_key_id"></a> [ebs\_kms\_key\_id](#input\_ebs\_kms\_key\_id) | KMS Key ID to encrypt EBS volumes on the GitLab Runner | `string` | `""` | no |
| <a name="input_ecr_region"></a> [ecr\_region](#input\_ecr\_region) | The AWS region of the ECR repository. Defaults to '' | `string` | `""` | no |
| <a name="input_ecr_uri"></a> [ecr\_uri](#input\_ecr\_uri) | The URI of the ECR image that you're wanting to authenticate to | `string` | `""` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment you're working in | `string` | `"DEV"` | no |
| <a name="input_instance_volume_size"></a> [instance\_volume\_size](#input\_instance\_volume\_size) | The size of the EBS volume on the GitLab runner | `number` | `30` | no |
| <a name="input_key_name"></a> [key\_name](#input\_key\_name) | Name of the SSH keypair to utilize in the runner launch template | `string` | `null` | no |
| <a name="input_private_subnets"></a> [private\_subnets](#input\_private\_subnets) | List of private subnets where the GitLab runner will be deployed. | `list(string)` | `null` | no |
| <a name="input_privileged"></a> [privileged](#input\_privileged) | Allows the docker containers to run in privileged mode. Necessary for DinD. Please note that this is insecure and should only be used if using DinD | `bool` | `false` | no |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Prefix of the project that will be used throughout the deployment | `string` | `""` | no |
| <a name="input_region"></a> [region](#input\_region) | AWS Region | `string` | `"us-east-1"` | no |
| <a name="input_runner_asg_desired_size"></a> [runner\_asg\_desired\_size](#input\_runner\_asg\_desired\_size) | Desired number of instances you want running in the runner ASG | `number` | `2` | no |
| <a name="input_runner_asg_max_size"></a> [runner\_asg\_max\_size](#input\_runner\_asg\_max\_size) | Max number of instances you want running in the runner ASG | `number` | `3` | no |
| <a name="input_runner_asg_min_size"></a> [runner\_asg\_min\_size](#input\_runner\_asg\_min\_size) | Minimum number of instances you want running in the runner ASG | `number` | `1` | no |
| <a name="input_runner_instance_type"></a> [runner\_instance\_type](#input\_runner\_instance\_type) | The EC2 instance type for the GitLab Runner | `string` | `"t3.medium"` | no |
| <a name="input_runner_role"></a> [runner\_role](#input\_runner\_role) | Name of the existing role to be used for deployment. | `string` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Common tags for all resources | `map(string)` | `{}` | no |
| <a name="input_user_data_file"></a> [user\_data\_file](#input\_user\_data\_file) | Path to custom user data file | `string` | `null` | no |
| <a name="input_user_data_variables"></a> [user\_data\_variables](#input\_user\_data\_variables) | Map of variables to be used inside of userdata | `map(any)` | `{}` | no |
| <a name="input_vpc_cidr_block"></a> [vpc\_cidr\_block](#input\_vpc\_cidr\_block) | VPC CIDR block | `string` | `null` | no |

#### Outputs

| Name | Description |
|------|-------------|
| <a name="output_asg_name"></a> [asg\_name](#output\_asg\_name) | Output of the name of runner ASG |
| <a name="output_private_subnets"></a> [private\_subnets](#output\_private\_subnets) | List of IDs of private subnets |
| <a name="output_runner_role"></a> [runner\_role](#output\_runner\_role) | Runner role |

<!-- END_TF_DOCS -->