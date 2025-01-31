
- [DEPLOYING FIRST APP](#deploying-first-app)
  - [Create VM:](#create-vm)
  - [SSH into the VM:](#ssh-into-the-vm)
  - [Once SSH into the VM, run these commands:](#once-ssh-into-the-vm-run-these-commands)
  - [To get the code onto the vm:](#to-get-the-code-onto-the-vm)
    - [**1st method:**](#1st-method)
    - [**2nd method:**](#2nd-method)
  - [Accessing the application:](#accessing-the-application)
    - [**Success with method 1:**](#success-with-method-1)
    - [**Success using method 2:**](#success-using-method-2)
  - [Connecting App VM to Db VM:](#connecting-app-vm-to-db-vm)
  - [Creating a reverse proxy:](#creating-a-reverse-proxy)
  - [Running the app in the background: Using PM2 and \&](#running-the-app-in-the-background-using-pm2-and-)
  - [Creating an Azure Image of VM](#creating-an-azure-image-of-vm)
  - [Creating a new VM with userdata configured:](#creating-a-new-vm-with-userdata-configured)
  - [BLOCKERS:](#blockers)
  - [Troubleshooting-](#troubleshooting-)



# DEPLOYING FIRST APP

## Create VM:
  - Name= `tech501-zainab-first-deploy-app-vm`
  - Image= Ubuntu Server 22.04 LTS - x64 Gen2
  - Select your SSH key stored in azure.
  - Networking- 
    - Security group name=  `tech501-zainab-sparta-app-allow-HTTP-SSH-3000`

## SSH into the VM:
  - `ssh -i ssh -i ~/.ssh/tech501-zainab-az-key adminuser@20.254.64.176`
  - `uname --all` - tells you about the image youre running.

## Once SSH into the VM, run these commands:
  - `sudo apt-get update -y` or `sudo apt update -y` same thing. 
    - Safe command- good way to check internet access. Doesn't actually upgrade anything yet!
  - `sudo apt-get upgrade -y`.
    - When purple confirmation screen shows up, **user input still required**- press tab and enter to press ok.
  - `sudo apt install nginx -y`
    - More user input required- press tab and enter.
  - `sudo systemctl status nginx` - check status of nginx.
  - **Dependencies**= anything that's required for the application to run. 
  - NodeJS installation-
  - `sudo DEBIAN_FRONTEND=noninteractive bash -c "curl -fsSL https://deb.nodesource.com/setup_20.x | bash -" && \
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y nodejs`

***** Make sure to copy this command from the markdown language terminal not the preview******
  - To check if it's installed:
    - `node -v` and `npm -v`. If you see the versions of these, means it's installed. 
  

## To get the code onto the vm:

Download code. Extract the code into the home folder:
- `C:\Users\zaina\nodejs20-sparta-test-app`

### **1st method:**
- Git clone command to get code from github repo to local machine.
- If you dont specify the name, it will get same name as github repo.
- `git clone <endpoint for remote repo> repo` 
  - git clones from github into a local repo called `repo`.

1. Upload zip file to my github repo. (Uploading unzipped was not possible- too many files and too large).
2. Use `git clone https://github.com/zainabx78/tech501-sparta-app repo` in the terminal of azure vm. 
3. Install the unzip package:
   1. `Sudo apt install unzip`
4. `unzip <nodejs app code folder name>`

*** Another way is to just push code from local repo to github and then clone it into azure vm.

### **2nd method:**
  - **cmd**- copy files specified to a location you specify.
    - Going to use private key for this command to gain access to vm through ssh.
  - `rsync` or `scp`.
    - rsync command is more efficient- only transfers differences between source and destination. 
  
Use this command to copy folder containing app folder from local pc to azure vm using my ssh key:

`scp -i ~/.ssh/tech501-zainab-az-key -r /c/Users/zaina/nodejs20-sparta-test-app adminuser@20.254.64.176:/home/adminuser`


  ## Accessing the application:

  - `ls` 
  - `cd repo` 
  - `cd app`
  - `npm install`- need full permissions over the app folder- clone it into home directory.
  - `node app.js` or `npm start`
  - Output should show app listening on port 3000.
  - To view the app- 
    - Need to add port 3000 into the network security group for our VM.
    - Higher rule number is lower priority.
    - Allow port 3000 in inbound rules.
    - Add `:3000` on the end of the google url for the app (Ip address).


### **Success with method 1:**
<br>

![alt text](<../Images/Screenshot 2025-01-27 153910.png>)
![alt text](<../Images/Screenshot 2025-01-27 153933.png>)

### **Success using method 2:**

<br>

![alt text](<../Images/Screenshot 2025-01-27 162852.png>)
![alt text](<../Images/Screenshot 2025-01-27 153933.png>)


## Connecting App VM to Db VM:

- Everytime you deploy/start up a vm from an image, to connect it to db you have to set the environment variable again and also seed the db:
  - `cd ~/repo/app`
  - `export DB_HOST=mongodb://10.0.3.4:27017/posts`
  - `printenv DB_HOST`
  - `npm install`
  - `npm start`


Worked- The app folder and node and npm were all ready when I deployed vm from an image. 

![alt text](<../Images/Screenshot 2025-01-27 172930.png>)

<br>

![alt text](<../Images/Screenshot 2025-01-27 172943.png>)

## Creating a reverse proxy:
In the app vm:

- nano into this file to edit the path- 
  - `sudo nano /etc/nginx/sites-available/default`
- Create a backup of the file before editing it.
  - `sudo cp -r /etc/nginx/sites-available/default /etc/nginx/sites-available/default-backup`
- Add this proxy pass into the file in the **location** section:
  - `proxy_pass http://localhost:3000;`
  - Make sure to take out the line already under location- 
    - Take out the line starting with `try_files.`
  
Should look like this at this point:
```bash
location / {
                # First attempt to serve request as file, then
                # as directory, then fall back to displaying a 404.

                proxy_pass http://localhost:3000;
}
```

- Restart the nginx app- 
  - `sudo systemctl restart nginx`
- Start the app- `npm start`
- Can also run app with `node app.js`
- nginx will redirect traffic 
  - we will no longer need to put 3000 at the end of the link. 
  - `http://20.39.216.155/` Just the Ip on port 80 will take us to the port 3000 link without specifying :3000.

## Running the app in the background: Using PM2 and &
1. Using pm2:
   - Install pm2 on the app vm:
     - ` sudo npm install -g pm2`
     - The -g flag means it's installed globally on your system.
     - Available to all users.
   - Start the pm2 process for your app:
     - ` pm2 start app.js --name "my-app"`
   - Check the status of the process:
     - `pm2 status`
   - To stop the app:
     - `pm2 stop "my-app"`
   - To restart the app:
     - `pm2 restart "my-app"`
   - Logs:
     - `pm2 logs "my-app"`
2. Using the `&` command:
    - `npm start &`
      - Even when you quit the port running terminal, the app will still be running.
    - `jobs`- to see the background processes running.
      - Should see the app.
    - See the job ID:
      - `jobs -l`
    - Kill the process:
      - `kill -15 <jobID>`
        - The medium level graceful termination.
    - To restart just run `npm start &` again.

## Creating an Azure Image of VM

- IMPORTANT: Won't be able to use the vm that you create the image from again! 
1. Move the app code from adminuser to root directory. 
`sudo mv /home/adminuser/repo /`
2. `sudo waagent -deprovision+user` - deletes the home directory (adminuser).
3. In azure portal, stop your vm.
4. From the vm portal, capture into an image.
5. Once image is created, create VM from the image.
6. When VM is created, ssh into it:
  - `ssh -i ~/.ssh/tech501-zainab-az-key adminuser@20.68.243.130`
7. Enter the root directory (where you moved your app folder into) 
  - `cd /` 
  - `cd repo`
  - `cd app`
  - `npm start`

## Creating a new VM with userdata configured:
- Use VM image to create a new vm. 
  - Name: 
  - License type: other.
  - Userdata sector:
    - bash script
    ````
    #!/bin/bash
    cd /repo/app
    export DB_HOST=mongodb://10.0.3.4:27017/posts
    pm2 start app.js

    ````
  - Create the vm and check if it works by just pasting publicIP into the browser.
  - Use /posts at the end of the browser link.
![alt text](<../Images/Screenshot 2025-01-29 150015.png>)


## BLOCKERS:

When creating the VMs, I configured them to have a security type of `Trusted launch virtual machines` instead of `Standard`
The issue:
- When creating the images from these VMs, I was unable to pick the `No, capture only a managed image` option. I was forced to pick the `Yes, share it to a gallery as a VM image version.` option instead.
![alt text](<../Images/Screenshot 2025-01-28 175826.png>)

![alt text](<../Images/Screenshot 2025-01-28 175858.png>)


## Troubleshooting- 
- If posts page not working, make sure there aren't any processes running in the background:
- `ps aux` to check any extra pm2 or node processes.
- `kill` the processes gracefully.
- Then try the `pm2 start app.js` command again. 
- Running app with pm2 with sudo:
  - `sudo -E pm2 start app.js`
    - need the -E flag to make sure sudo can access the environment variables. 
    - Only need sudo -E if you dont have permissions over that folder.

App- isn't a system service so we cannot enable it like the mongodb server.