#!/bin/bash

# Update packages and install required tools
sudo yum update -y
sudo yum install -y 
sudo yum install docker -y

# Start Docker and enable it on startup
sudo systemctl start docker
sudo systemctl enable docker

# Install GitLab Runner
curl -LJO https://gitlab-runner-downloads.s3.amazonaws.com/latest/rpm/gitlab-runner_amd64.rpm
sudo yum install -y ./gitlab-runner_amd64.rpm
rm -f gitlab-runner_amd64.rpm

# Generate a unique system ID
SYSTEM_ID=$(uuidgen)

# Register the GitLab Runner
sudo gitlab-runner register \
    --non-interactive \
    --url "${gitlab_url}" \
    --registration-token "${gitlab_runner_registration_token}" \
    --executor "docker" \
    --docker-image "alpine:latest" \
    --description "docker-runner-$SYSTEM_ID" \

# Create a new systemd service file for GitLab Runner
sudo bash -c "cat > /etc/systemd/system/gitlab-runner.service" << 'EOF'
[Unit]
Description=GitLab Runner
After=syslog.target network.target

[Service]
ExecStart=/usr/bin/gitlab-runner "run" "--working-directory" "/var/lib/gitlab-runner" "--config" "/etc/gitlab-runner/config.toml" "--service" "gitlab-runner" "--syslog" "--user" "root"
Restart=always
StartLimitInterval=0

[Install]
WantedBy=multi-user.target
EOF

# Reload the systemd configuration
sudo systemctl daemon-reload

# Disable the default GitLab Runner service
sudo systemctl disable gitlab-runner

# Enable and start the new GitLab Runner service
sudo systemctl enable gitlab-runner.service
sudo systemctl start gitlab-runner.service