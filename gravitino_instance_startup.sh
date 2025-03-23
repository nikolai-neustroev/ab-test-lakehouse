#!/bin/bash
set -e

# (Optional) Update the Debian OS packages.
# sudo apt update && sudo apt upgrade -y

# (Optional) Reboot if required.
# sudo reboot

# Install Java 17 Amazon Corretto.
wget -O - https://apt.corretto.aws/corretto.key | sudo gpg --dearmor -o /usr/share/keyrings/corretto-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/corretto-keyring.gpg] https://apt.corretto.aws stable main" | sudo tee /etc/apt/sources.list.d/corretto.list
sudo apt-get update
sudo apt-get install -y java-17-amazon-corretto-jdk

# (Optional) Verify the Java version.
# java -version

# Download Gravitino.
wget -nv -O /home/${username}/gravitino-0.8.0-incubating-bin.tar.gz https://github.com/apache/gravitino/releases/download/v0.8.0-incubating/gravitino-0.8.0-incubating-bin.tar.gz

# Extract the Gravitino archive.
tar -xzf /home/${username}/gravitino-0.8.0-incubating-bin.tar.gz -C /home/${username}

# Change into the extracted directory.
chown -R ${username}:${username} /home/${username}/gravitino-0.8.0-incubating-bin
