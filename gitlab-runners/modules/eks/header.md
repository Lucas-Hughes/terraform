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

## Known Issues

- When using the EKS module to create more than one eks cluster in the same account, coredns may fail to install after 20 minutes. This does not prevent the runner from working, but the terraform resource will fail to create. 

This is a work in progress

## Usage

Follow these steps to deploy the GitLab Runner on your AWS infrastructure:

### Step 1 (Optional if completed previously): Prerequisites

## TODO

Work in progress to flesh this out for more public use

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

### Step 3: Create a GitLab Runner

Due to token architecture changes, you need to create the GitLab runner manager inside the GitLab console and get a token from there.

- If you are working at the group level, navigate to `group -> build -> runners -> New Group Runner`, create a new runner, and grab the token.
- If you are working at the project level, navigate to `settings -> CI/CD -> runners -> New Project Runner`, create a new runner, and grab the token.

Remember, you need to have maintainer/owner permissions in GitLab to perform these actions.

### Step 4: Update the Configuration

1. Update the `terraform.tfvars` file with your gitlab runner token you created in step 2.

    - gitlab_runner_token = "glrt-xxxxxxxxxxxxxxx"

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
