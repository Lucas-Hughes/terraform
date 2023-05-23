import boto3
import collections
import datetime
import sys
import pprint
import os
import json

ec = boto3.client('ec2')
ec2_instance_id = os.environ['instance_id']
label_id = os.environ['label_id']
no_reboot = os.environ['reboot'] == '0'
block_device_mappings = json.loads(str(os.environ['block_device_mappings']))

def lambda_handler(event, context):
    try:
        retention_days = int(os.environ['retention'])
    except ValueError:
        retention_days = 14
    create_time = datetime.datetime.now()
    create_fmt = create_time.strftime('%Y-%m-%d')
    AMIid = ec.create_image(InstanceId=ec2_instance_id,
                            Name=f"{label_id}-{ec2_instance_id}-{create_fmt}",
                            Description=f"{label_id}-{ec2_instance_id}-{create_fmt}",
                            NoReboot=no_reboot, DryRun=False,
                            BlockDeviceMappings=block_device_mappings)

    print(f"Retaining AMI {AMIid['ImageId']} of instance {ec2_instance_id} for {retention_days} days")

    delete_date = datetime.date.today() + datetime.timedelta(days=retention_days)
    delete_fmt = delete_date.strftime('%m-%d-%Y')

    ec.create_tags(
        Resources=[AMIid['ImageId']],
        Tags=[
            {'Key': 'DeleteOn', 'Value': delete_fmt},
        ]
    )
