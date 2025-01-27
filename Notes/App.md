
# DEPLOYING FIRST APP

## Create VM:
  - Name= `tech501-zainab-first-deploy-app-vm`
  - Image= Ubuntu Server 22.04 LTS - x64 Gen2
  - Select your SSH key stored in azure.
  - Networking- 
    - Security group name=  `tech501-zainab-sparta-app-allow-HTTP-SSH-3000`

### SSH into the VM:
  - `ssh -i ssh -i ~/.ssh/tech501-zainab-az-key adminuser@20.254.64.176`
  - `uname --all` - tells you about the image youre running.

### Once SSH into the VM, run these commands:
  - `sudo apt-get update -y` or `sudo apt update -y` same thing.
  - `sudo apt-get upgrade -y`.
    - When purple confirmation screen shows up, **user input still required**- press tab and enter to press ok.
  - `sudo apt install nginx -y`
    - More user input required- press tab and enter.
  - `sudo systemctl status nginx` - check status of nginx.
  - Dependencies= anything that's required for the application to run. 
  - NodeJS installation-
    - `sudo DEBIAN_FRONTEND=noninteractive bash -c "curl -fsSL https://deb.nodesource.com/setup_20.x | bash -" && \
    sudo DEBIAN_FRONTEND=noninteractive 
    apt-get install -y nodejs`
  - To check if it's installed:
    - `node -v` and `npm -v`. If you see the versions of these, means it's installed. 
  

  ### To get the code onto the vm:

Download code. Extract the code into the home folder:
- `C:\Users\zaina\nodejs20-sparta-test-app`

**1st method:**
- Git clone command to get code from github repo to local machine.
- If you dont specify the name, it will get same name as github repo.
- `git clone <endpoint for remote repo> repo` 
  - git clones from github into a local repo called `repo`.

1. Upload zip file to my github repo. (Uploading unzipped was not possible- too many files and too large).
2. Use `git clone https://github.com/zainabx78/tech501-sparta-app repo` in the terminal of azure vm. 
3. Install the unzip package:
   1. `Sudo apt install unzip`
4. `unzip <nodejs app code folder name>`


**2nd method:**
  - **cmd**- copy files specified to a location you specify.
    - Going to use private key for this command to gain access to vm through ssh.
  - `rsync` or `scp`.
    - rsync command is more efficient- only transfers differences between source and destination. 
  
Use this command to copy folder containing app folder from local pc to azure vm using my ssh key:

`scp -i ~/.ssh/tech501-zainab-az-key -r /c/Users/zaina/nodejs20-sparta-test-app adminuser@20.254.64.176:/home/adminuser`


  ### Accessing the application:

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


**Success with method 1:**
![alt text](<../Images/Screenshot 2025-01-27 153910.png>)
![alt text](<../Images/Screenshot 2025-01-27 153933.png>)

**Success using method 2:**
![alt text](<../Images/Screenshot 2025-01-27 162852.png>)
![alt text](<../Images/Screenshot 2025-01-27 153933.png>)