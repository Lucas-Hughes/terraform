#!/bin/bash

# Stop ssm-agent
systemctl stop amazon-ssm-agent

# Update stuff
sudo yum update -y

# Ensure Docker is installed; while loop is due to recent bugs. may remove in future
while true; do
    # Check if docker is installed
    if rpm -q docker &> /dev/null; then
        echo "Docker is already installed!"
        break
    else
        echo "Installing Docker..."
        sudo yum install docker -y
        # After installing, check if the installation was successful
        if rpm -q docker &> /dev/null; then
            echo "Docker installed successfully!"
            break
        else
            echo "Failed to install Docker. Retrying..."
            sleep 10
        fi
    fi
done

# Amazon ECR Credential Helper so the runner does not lose auth to ECR
sudo yum install -y amazon-ecr-credential-helper

# Start Docker and enable it on startup
sudo systemctl start docker
sudo systemctl enable docker

# Install GitLab Runner
sudo curl -LJO https://gitlab-runner-downloads.s3.amazonaws.com/latest/rpm/gitlab-runner_amd64.rpm
sleep 5
sudo dnf install -y ./gitlab-runner_amd64.rpm
rm -f gitlab-runner_amd64.rpm

# Start ssm-agent
systemctl start amazon-ssm-agent

# Generate a unique system ID
SYSTEM_ID=$(uuidgen)

# Register the GitLab Runner
sudo gitlab-runner register \
    --non-interactive \
    --url "https://gitlab.com" \
    --registration-token "${gitlab_runner_token}" \
    --docker-image "${docker_runner_image}" \
    --executor "docker" \
    --description "docker-runner-$SYSTEM_ID" \
    --docker-volumes "/var/run/docker.sock:/var/run/docker.sock" \
    --docker-volumes "/cache" \
    --docker-volumes "/data:/data" \

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

# Make directory to ensure it doesn't continually restart
sudo mkdir -p /var/lib/gitlab-runner
sudo chown gitlab-runner:gitlab-runner /var/lib/gitlab-runner

# Reload the systemd configuration
sudo systemctl daemon-reload

# Disable the default GitLab Runner service
sudo systemctl disable gitlab-runner

# Enable and start the new GitLab Runner service
sudo systemctl enable gitlab-runner.service
sudo sed -i "s/concurrent.*/concurrent = ${concurrency}/" /etc/gitlab-runner/config.toml
sudo sed -i '/\[runners.docker\]/,/\[/{s/\(privileged = \).*/\1'"${privileged}"'/;}' /etc/gitlab-runner/config.toml
sudo systemctl restart gitlab-runner

if aws ecr get-login-password --region ${ecr_region} | docker login --username AWS --password-stdin ${ecr_uri}; then
    echo "Login successful!"
else
    echo "Login failed!"
    exit 0
fi

# Add Amazon ECR Credential helper config:
if [[ -n "${ecr_uri}" ]]; then
    auth_config="DOCKER_AUTH_CONFIG={\"credHelpers\":{\"${ecr_uri}\":\"ecr-login\"}}"
    echo "Adding auth config: $auth_config"
    
    # Appending the config to the toml file
    sed -i "/\[runners.docker\]/a environment = \"$auth_config\"" /etc/gitlab-runner/config.toml
else
    echo "No ECR URI provided. Skipping."
fi