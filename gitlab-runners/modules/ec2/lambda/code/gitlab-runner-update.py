import boto3
import json

lt_name = 'gitlab-runner-lt'
asg_name = 'gitlab-runner-asg'
ssm_parameter_name = 'pcm-amznlinux2023min_x86_64-prod-latest'

ssm = boto3.client('ssm')
ec2 = boto3.client('ec2')
asg = boto3.client('autoscaling')

def lambda_handler(event, context):
    # Retrieve the AMI ID from Parameter Store
    response = ssm.get_parameter(Name=ssm_parameter_name)
    ami_id = response['Parameter']['Value']

    # Retrieve the launch template
    launch_template = ec2.describe_launch_templates(LaunchTemplateNames=[lt_name])['LaunchTemplates'][0]
    new_version_number = int(launch_template['LatestVersionNumber']) + 1

    # Create a new version of the launch template with the new AMI ID
    response = ec2.create_launch_template_version(
        LaunchTemplateId=launch_template['LaunchTemplateId'],
        SourceVersion=str(launch_template['LatestVersionNumber']),
        LaunchTemplateData={
            'ImageId': ami_id
        }
    )
    updated_launch_template = response['LaunchTemplateVersion']
    ec2.modify_launch_template(
        LaunchTemplateId=launch_template['LaunchTemplateId'],
        DefaultVersion=str(new_version_number)
    )

    # Start a rolling instance refresh for the auto-scaling group using the new launch template version
    response = asg.start_instance_refresh(
        AutoScalingGroupName=asg_name,
        Strategy='Rolling',
        Preferences={
            'MinHealthyPercentage': 90,
            'InstanceWarmup': 300
        },
        LaunchTemplate={
            'LaunchTemplateId': launch_template['LaunchTemplateId'],
            'Version': str(new_version_number)
        }
    )

    print(json.dumps(response, default=str))
