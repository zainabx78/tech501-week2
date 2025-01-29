- [Create a VM](#create-a-vm)
  - [Dependencies:](#dependencies)
  - [Installing MongoDB:](#installing-mongodb)
    - [Change BindIP:](#change-bindip)
    - [Restart mongodb server after making change:](#restart-mongodb-server-after-making-change)
- [Connecting the App and database:](#connecting-the-app-and-database)
  - [SSH into the 2 VM's in different git bash windows:](#ssh-into-the-2-vms-in-different-git-bash-windows)
  - [In the db VM:](#in-the-db-vm)
  - [In the App VM:](#in-the-app-vm)
  - [Connecting the db VM and the app VM: Working in APP VM](#connecting-the-db-vm-and-the-app-vm-working-in-app-vm)
    - [Setting up an environment variable to use for connecting:](#setting-up-an-environment-variable-to-use-for-connecting)
      - [Need to be **Working in the App VM:**](#need-to-be-working-in-the-app-vm)
  - [Create Environment Variable: APP VM](#create-environment-variable-app-vm)
  - [Creating an image from the DB VM:](#creating-an-image-from-the-db-vm)
  - [BLOCKERS:](#blockers)
  - [Levels of automate: Lowest to highest:](#levels-of-automate-lowest-to-highest)


# Create a VM

## Dependencies:

- Name: tech501-zainab-sparta-app-db-vm
- Ubuntu 22.04 LTS image.
- Same size as usual.
- Network security group: Allow SSH.
- Public Ip: Yes
- Vnet: 2 subnet vnet already created. 
- Subnet: Use the private subnet for the database.
- By default, azure allows devices to talk to eachother on the same network(vnet, vpc)- don't need to allow mongodb database port access. (Unlike AWS).
- SSH key- already stored on azure.

SSH into the VM:
- `ssh -i ~/.ssh/tech501-zainab-az-key adminuser@4.234.8.12`
- Run update and upgrade commands:
  - `sudo apt update -y` `sudo apt upgrade -y`

## Installing MongoDB:

- Mongo db version 7.0.6
- Install gnupg and curl:
  - `sudo apt-get install gnupg curl`
- Download gpg key:
  - `curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc | \
   sudo gpg -o /usr/share/keyrings/mongodb-server-7.0.gpg \
   --dearmor`
- Create file list:
  - `echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list`
- Update:
  - `sudo apt-get update`
- Install a specific release: 7.0.6
  - `sudo apt-get install -y mongodb-org=7.0.6 mongodb-org-database=7.0.6 mongodb-org-server=7.0.6 mongodb-mongosh mongodb-org-mongos=7.0.6 mongodb-org-tools=7.0.6`
- EXTRAS: Can ignore. Can use extra commands to ensure that this version doesnt get upgraded with other components when upgrading:
  - `echo "mongodb-org hold" | sudo dpkg --set-selections
echo "mongodb-org-database hold" | sudo dpkg --set-selections
echo "mongodb-org-server hold" | sudo dpkg --set-selections
echo "mongodb-mongosh hold" | sudo dpkg --set-selections
echo "mongodb-org-mongos hold" | sudo dpkg --set-selections
echo "mongodb-org-tools hold" | sudo dpkg --set-selections`
- Check status:
  - `sudo systemctl status mongod`
  - By default it starts turned off.
- Start mongodb:
  - `sudo systemctl start mongod`
- Check status:
  - `sudo systemctl status mongod`
    - Should be running. 


### Change BindIP:

Enter this:
- `sudo nano /etc/mongod.conf`
- Change the bind IP to 0.0.0.0
- 0.0.0.0 means it's accessible from anywhere.
- Don't do this for production.

### Restart mongodb server after making change:

- `sudo systemctl restart mongod`
- `sudo systemctl status mongod`
  - Should be running.

# Connecting the App and database:

## SSH into the 2 VM's in different git bash windows:
1. The App VM with nodejs and npm and the app installed.
    - If you created an image use the vm created from the image.
    - If you created an image from the vm then you won't be able to use that vm anymore.
2. The db VM with mongodb installed and running

## In the db VM:
-  `sudo systemctl is-enabled mongod`
   -  Will see the db isn't enabled. That means it won't start on start up of VM when VM is stopped and started.
-  `sudo systemctl enable mongod`
   -  Makes sure it starts up on start of VM everytime.
   -  Doesn't start db just with enable this time. But will do every other time when you start VM.
-   `sudo systemctl start mongod`
    -   Still need to start it this time.
-   `sudo systemctl status mongod`
    -   Should be running.

## In the App VM:

- cd into the app folder and then `npm start` to run the app.
- In browser- open the app with `PublicIP:3000`.
  - Should be working!


## Connecting the db VM and the app VM: Working in APP VM

### Setting up an environment variable to use for connecting:

#### Need to be **Working in the App VM:**

- On the same network so can use private IP. Can use public IP too but not necessary!
- `10.0.3.4` = db private IP.

Switch into the app folder:
- `cd /repo/app`

## Create Environment Variable: APP VM
*** Need to do this everytime I restart vm or stop and start it.
- `export DB_HOST=mongodb://10.0.3.4:27017/posts`
  - Use the private IP of db in this command.
  - 27017 is the default port for mongodb.

Check if you have set it up correctly:
- `printenv DB_HOST`

Create dummy records:
- `npm install`
    - Clears the db and seeds it (adds records).
    - Also checks for db connection.
    - Also checks for app vulnerabilities.
Start the App again and see db records connected:
- `npm start`
- Enter `PublicIpOfAppVM:3000/posts` to see the connected db.

*** If you need to re-seed db and it doesn't work:
npm install might not populated db occasionally- may need to manually run a command to seed db:
- `node seeds/seed.js` 
- Need to be in app folder in app vm. 



## Creating an image from the DB VM:

1. First run this command:
- `sudo waagent -deprovision+user`
  - Deletes the adminuser (home directory).
  
2. Stop the VM on the azure portal.
3. Capture the image
4. Name: tech501-zainab-sparta-db-ready-to-run-img

Deploy a VM from the image:

- Name: `tech501-zainab-deploy-db-generalised-vm`

Check if the vm has mongodb installed already:
- `sudo systemctl status mongod`   
  - Should see monogdb running already as it was enabled in the vm we used to create image.



## BLOCKERS:

When creating the VMs, I configured them to have a security type of `Trusted launch virtual machines` instead of `Standard`
The issue:
- When creating the images from these VMs, I was unable to pick the `No, capture only a managed image` option. I was forced to pick the `Yes, share it to a gallery as a VM image version.` option instead.
![alt text](<../Images/Screenshot 2025-01-28 175826.png>)

![alt text](<../Images/Screenshot 2025-01-28 175858.png>)



Solution= 
- I re-created the VM's for the app and db again, this time changing the security type to standard. 
  I was able to create images with the `No, capture only a managed image` option this time. 
  
**WORKS!**

## Levels of automate: Lowest to highest:
1. **Manually-** 
  - SSH into the machine and run the commands manually.
2. **Bash scripting**- still need to ssh into the vm and then manually run the script. Not fully automatic.
3. **User data-**
  - Only runs once (can't start and stop vm).
  - Runs the script as root user.
  - No ssh required to run the script it automatically runs on start of vm.
4. **Image**- has everything you created on disk except home directory (gets wiped).


