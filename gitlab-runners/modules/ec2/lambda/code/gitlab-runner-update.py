import boto3
import logging
import os

logger = logging.getLogger()
logger.setLevel(logging.INFO)

lt_name = os.environ['LAUNCH_TEMPLATE_NAME']
asg_name = os.environ['AUTOSCALING_GROUP_NAME']

ec2 = boto3.client('ec2')
asg = boto3.client('autoscaling')

def lambda_handler(event, context):
    try:
        response = ec2.describe_images(
            Filters=[
                {'Name': 'name', 'Values': ['amzn2-ami-hvm-*-x86_64-gp2']},
                {'Name': 'virtualization-type', 'Values': ['hvm']}
            ],
            Owners=['amazon'],
            MostRecent=True
        )
        
        ami_id = response['Images'][0]['ImageId']
        
        # Retrieve the launch template
        launch_template = ec2.describe_launch_templates(LaunchTemplateNames=[lt_name])['LaunchTemplates'][0]
        
        # Check if the AMI ID in the latest launch template version is already up-to-date
        current_ami_id = ec2.describe_launch_template_versions(
            LaunchTemplateName=lt_name,
            Versions=[str(launch_template['LatestVersionNumber'])]
        )['LaunchTemplateVersions'][0]['LaunchTemplateData']['ImageId']

        if current_ami_id != ami_id:
            # Create a new version of the launch template with the new AMI ID
            response = ec2.create_launch_template_version(
                LaunchTemplateName=lt_name,
                SourceVersion=str(launch_template['LatestVersionNumber']),
                VersionDescription='Update with the latest AMI ID',
                LaunchTemplateData={
                    'ImageId': ami_id
                }
            )
            
            new_version_number = response['LaunchTemplateVersion']['VersionNumber']

            # Update the auto-scaling group to use the new launch template version
            asg.update_auto_scaling_group(
                AutoScalingGroupName=asg_name,
                LaunchTemplate={
                    'LaunchTemplateName': lt_name,
                    'Version': str(new_version_number)
                }
            )
            
            logger.info(f"Updated the launch template {lt_name} and auto-scaling group {asg_name} with the new AMI ID {ami_id}.")
        else:
            logger.info(f"The AMI ID {ami_id} is already in use in the launch template {lt_name}.")
    except Exception as e:
        logger.error(f"An error occurred: {e}")
        raise
