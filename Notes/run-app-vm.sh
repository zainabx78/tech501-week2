#!/bin/bash
# Supresses all prompts
# export DEBIAN_FRONTEND=noninteractive


# Update and upgrade
sudo apt-get update -y 
DEBIAN_FRONTEND=noninteractive sudo apt-get upgrade -y

# Install nginx
DEBIAN_FRONTEND=noninteractive sudo apt install nginx -y

# Install Nodejs
sudo DEBIAN_FRONTEND=noninteractive bash -c "curl -fsSL https://deb.nodesource.com/setup_20.x | bash -" && \
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y nodejs

# Install code onto vm
git clone https://github.com/zainabx78/tech501-sparta-app repo

# Install unzip package
sudo apt install unzip

# Unzip 
cd repo
unzip nodejs20-sparta-test-app.zip

#Installing pm2
sudo npm install -g pm2

# Accessing application
cd app
npm install

# Connecting to db
cd /repo/app
export DB_HOST=mongodb://10.0.3.4:27017/posts
pm2 start app.js