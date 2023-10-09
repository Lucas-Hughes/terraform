#!/bin/bash

# Stop ssm-agent
systemctl stop amazon-ssm-agent

# Update stuff
sudo yum update -y

echo "${user_data_variables["gl_runner_token"]}" > myrunnertoken.txt
echo "${user_data_variables["test_variable"]}" > mytestvariable.txt