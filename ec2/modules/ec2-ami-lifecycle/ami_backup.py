import boto3
import datetime
import os
import json

ec = boto3.client('ec2')

def get_block_device_mappings(ec2_instance_id, block_device_mappings):
    instance_info = ec.describe_instances(InstanceIds=[ec2_instance_id])
    current_device_mappings = instance_info['Reservations'][0]['Instances'][0]['BlockDeviceMappings']

    # If block_device_mappings is empty, return all current device mappings
    if not block_device_mappings:
        return current_device_mappings

    device_names_to_include = [mapping['DeviceName'] for mapping in block_device_mappings]

    new_device_mappings = []
    for device_mapping in current_device_mappings:
        if device_mapping['DeviceName'] in device_names_to_include:
            valid_keys = ['DeviceName', 'VirtualName', 'Ebs']
            filtered_mapping = {k: v for k, v in device_mapping.items() if k in valid_keys}
            if 'Ebs' in filtered_mapping:
                valid_ebs_keys = ['DeleteOnTermination', 'Iops', 'SnapshotId', 'VolumeSize', 'VolumeType', 'KmsKeyId', 'Throughput', 'OutpostArn', 'Encrypted']
                filtered_mapping['Ebs'] = {k: v for k, v in filtered_mapping['Ebs'].items() if k in valid_ebs_keys}
            new_device_mappings.append(filtered_mapping)
        else:
            new_device_mappings.append({'DeviceName': device_mapping['DeviceName'], 'NoDevice': ""})

    return new_device_mappings

def lambda_handler(event, context):
    ec2_instance_id = os.environ['instance_id']
    no_reboot = os.environ['reboot'] == '0'
    block_device_mappings = json.loads(os.environ['block_device_mappings'])

    try:
        retention_days = int(os.environ['retention'])
    except ValueError:
        retention_days = 14

    create_time = datetime.datetime.now()
    create_fmt = create_time.strftime('%Y-%m-%d-%H-%M-%S')

    # Fetch instance information
    instance_info = ec.describe_instances(InstanceIds=[ec2_instance_id])

    # Assume the instance has a 'Name' tag. If no 'Name' tag is found, use the instance ID.
    instance_name = ec2_instance_id
    for tag in instance_info['Reservations'][0]['Instances'][0]['Tags']:
        if tag['Key'] == 'Name':
            instance_name = tag['Value']
            break

    ami_name = f"{os.environ['t_AppID']}-{instance_name}-{create_fmt}"
    block_device_mappings = get_block_device_mappings(ec2_instance_id, block_device_mappings)

    AMIid = ec.create_image(InstanceId=ec2_instance_id,
                            Name=ami_name,
                            Description=ami_name,
                            NoReboot=no_reboot, DryRun=False,
                            BlockDeviceMappings=block_device_mappings)

    print(f"Retaining AMI {AMIid['ImageId']} of instance {ec2_instance_id} for {retention_days} days")

    delete_date = datetime.date.today() + datetime.timedelta(days=retention_days)
    delete_fmt = delete_date.strftime('%m-%d-%Y')

    # Decode the list of tag keys from the 'tag_keys' environment variable
    tag_keys = json.loads(os.environ['tag_keys'])

    # Construct the list of tags for the AMI
    tags = [{'Key': 'DeleteOn', 'Value': delete_fmt}]

    # Add tags dynamically using the keys from 'tag_keys'
    for key in tag_keys:
        tags.append({'Key': key, 'Value': os.environ[key]})

    # Add the 'Name' tag
    tags.append({'Key': 'Name', 'Value': ami_name})

    ec.create_tags(
        Resources=[AMIid['ImageId']],
        Tags=tags
    )
