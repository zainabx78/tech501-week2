- [Securing the DB using a 3-subnet architecture](#securing-the-db-using-a-3-subnet-architecture)
- [PLAN](#plan)
  - [VNET](#vnet)
    - [The public subnet with APP inside:](#the-public-subnet-with-app-inside)
    - [The private subnet with database inside:](#the-private-subnet-with-database-inside)
- [Lab](#lab)
  - [Create a Vnet](#create-a-vnet)
  - [Create a db VM from your db image:](#create-a-db-vm-from-your-db-image)
  - [Creating an app VM from the app image:](#creating-an-app-vm-from-the-app-image)
  - [SSH into the App VM:](#ssh-into-the-app-vm)
  - [Ping the db VM through the App VM:](#ping-the-db-vm-through-the-app-vm)
  - [Create NVA:](#create-nva)
  - [Create Route Table:](#create-route-table)
  - [Enabling IP forwarding in azure:](#enabling-ip-forwarding-in-azure)
  - [Enabling IP forwarding in linux:](#enabling-ip-forwarding-in-linux)
  - [Creating Iptables Rules](#creating-iptables-rules)
  - [Edit DB NSG to make it more secure:](#edit-db-nsg-to-make-it-more-secure)
    - [Allow mongodb:](#allow-mongodb)
    - [Deny everything else](#deny-everything-else)
  - [Deleting Resources:](#deleting-resources)
    - [Deleting VM's:](#deleting-vms)
    - [Deleting Route Table:](#deleting-route-table)
    - [Deleting 3-subnet Vnet:](#deleting-3-subnet-vnet)


# Securing the DB using a 3-subnet architecture

![alt text](<../Images/NVA diagram.png>)

STEPS:
1. Create Vnet.
2. Setup the Subnets.
3. Create the DB VM with db image.
4. Create App VM with app image.
5. Setup App and DB connection
6. Setup route tables.
7. Create NVA- filter traffic.



# PLAN

When web traffic comes in, hits the public IP of the Public subnet.
Because of our network security group (NSG)- port 80 allowed, the traffic will be allowed in.
The traffic hits the app vm.
Because of the export command (env variables)- the app vm knows it has to send the request to the db- private IP on the mongodb port.
Associate the route table with the public subnet (where the traffic comes from)- monitoring that traffic.
We have to force a different route to happen- Route table.
- If there are packets with destination of private subnet, next hop has to be NVA! It's not all traffic just the one going to private subnet. (Has to meet condition).
- Any traffic headed for the private subnet will have to enter the DMZ (NVA) subnet first through the dmz private IP.
Once the packets reach NVA, the NVA inspects the packets.
- Ip forwarding enabled so the packets have to go through the rules (iptables). 
- Fowards traffic to the db machine (mongodb traffic was allowed in db nsg).
Db can send the info requested back to the app vm (no nva forced on the way back).



## VNET
- 10.0.0.0/16 CIDR block.
  
### The public subnet with APP inside:

- 10.0.2.0/24 subnet CIDR block.
- Public Ip associated with app VM.
  - Web traffic coming in through HTTP- potentially dangerous.
- NIC - responsible for communication in and out of the VM.
- NSG - rules:
  - Allow port 80 (HTTP).
  - Allow port 22 (SSH).

### The private subnet with database inside:

- 10.0.4.0/24 subnet CIDR block.
- Public Ip address associated with db VM.
  - Needed for you to SSH in. 
  - Other people could try to also SSH- potentially dangerous.
- NIC card.
- NSG - rules:
  - Allow SSH and mongodb
  - Deny all other traffic- Setup stricter rules.
  - Bcs by default azure allows all traffic within the same vnet.
- Private subnet box checked
  - Prevents internet access

How to SSH into the DB more securely:
- **Remove the Public Ip and use the App VM to SSH into the DB VM.**

NEW SUBNET: DMZ-subnet
- NVA- Network virtual appliance.
  - Acts as a firewall (filter)
  for the traffic for db.
  - Role= to filter all traffic that's headed for the db machine.
- 10.0.3.0/24 subnet CIDR block.
- Has a public IP associated with it.
- NIC associated with it. **Needs IP forwarding enabled in azure.**
- **Need IP fowarding in linux too after logging in.**
  - Ip tables rules.
- NSG- rules:
    - Allow SSH initially. potentially dangerous.
- Need a route table:
  - Controls the routes of traffic through vnet.
  - When reqs coming out of app vm (pub sub), need to be routed directly to the NVA.
  - NVA needs to forward traffic to DB VM if it allows the safe traffic through.
- Forwarded traffic (filtered).

# Lab
## Create a Vnet
- 3 subnets (Public, private and dmz).

## Create a db VM from your db image:
- Name: tech501-zainab-in-subnet-sparta-app-db
- AZ: Check in diagram, db is in the 3rd subnet so put into zone 3.
- User= adminuser
- SSH key- Use existing in azure.
- Vnet:tech501-zainab-3-subnet-vnet
- Subnet: Private subnet
- ** No public Ip address.**
- Allow only SSH port access.
- Because it's in a private subnet with no public IP, had to use an image which already had mongodb installed!

## Creating an app VM from the app image:
- Name: tech501-zainab-in-3-subnet-sparta-app-vm
- AZ: Zone 1.
- Username: adminuser
- SSH key: Use existing stored in azure
- Ports: Allow port 80 and 22.
- Same 3-subnet vnet.
- Public subnet
- In advanced page:
  - Add user data:
```
#!/bin/bash

cd /repo/app
export DB_HOST=mongodb://10.0.4.4:27017/posts
pm2 start app.js
```
- Make sure you edit private Ip and add the one from the db vm you created.
- Check if you can connect to the vm and db: `http://172.187.177.243/posts`

## SSH into the App VM:
- `ssh -i ~/.ssh/tech501-zainab-az-key adminuser@172.187.177.243`

## Ping the db VM through the App VM:
- `ping 10.0.4.4`

![alt text](<../Images/Screenshot 2025-01-31 161951.png>)

At this point the ping should work! 
- No rules to stop it yet. 

## Create NVA:
- Create a VM: without image.
  - Name: tech501-zainab-in-3-subnet-sparta-app-nva
  - AZ: Zone 2
  - Image: Ubuntu 22.04 LTS
  - Username: Adminuser
  - SSH: Existing key in azure
  - Ports: Allow SSH (22)
  - vnet: tech501-zainab-3-subnet-vnet
  - dmz subnet
  - Public Ip enabled.
  - Standard security type.

## Create Route Table:
- Name: tech501-zainab-to-private-subnet-rt
- Tags: Name-owner, value-zainab
- Create.
- Go to the rt resource- settings-routes-add route.
  - Add route-
  - Name: to-private-subnet-route
  - Destination type- IP addresses
  - CIDR block- destination IP address- `10.0.4.0/24` (private subnet)
  - Next hop type- Virtual appliance.
  - Next hop address- `10.0.3.4` (NVA private IP).
 
- Go to subnets- associate-
  - Associate it with the subnet where the traffic is coming out of.
  - Associate it to the public subnet.

![
](<../Images/Screenshot 2025-01-31 161658.png>)


## Enabling IP forwarding in azure:
- NVA VM
- Network settings
  - Click on the network interface.
- Ip configuration on the left
  - Check the box that says `Enable Ip forwarding`.
  - Apply changes.

## Enabling IP forwarding in linux:
- SSH into the NVA VM
- `ssh -i ~/.ssh/tech501-zainab-az-key adminuser@20.77.65.180`
- Check if IP forwarding is enabled:
  - `sysctl net.ipv4.ip_forward`
  - If output =0, forwarding is disabled.
- To enable it:
  - `sudo nano /etc/sysctl.conf`
  - Uncomment the line `net.ipv4.ip_forward=1` - Take off the # at the start.
  
Should go from this:

![alt text](<../Images/Screenshot 2025-01-31 161323.png>)

To this:

![alt text](<../Images/Screenshot 2025-01-31 161333.png>)

- Reload the config file:
  - `sudo sysctl -p`
- Value should be 1
- Can run the `sysctl net.ipv4.ip_forward` command again to ensure value is changed to 1.
- 
![alt text](<../Images/Screenshot 2025-01-31 161904.png>)

## Creating Iptables Rules

When setting Iptables rules up, if set up in the wrong order, may lock yourself out of the vm.

These rules restrict the traffic so only the right traffic from the app VM is getting into the db VM.

Creating a bash script to automate this:
- ` nano config-ip-tables.sh`
```bash
#!/bin/bash
 
# configure iptables
# This setup protects your system by only allowing necessary connections while blocking everything else. 

echo "Configuring iptables..."
 
# Allows all traffic on the loopback interface (lo), enabling communication within the local machine. Allows the computer to talk to itself (for example, when programs communicate internally).
sudo iptables -A INPUT -i lo -j ACCEPT
sudo iptables -A OUTPUT -o lo -j ACCEPT
 
# Allows incoming traffic that is part of an existing connection or related to an already established one. Allows responses to requests you already made (like when you visit a website, the replies from the website can come back).
sudo iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
 
# Lets your computer reply to connections that have already been established.
sudo iptables -A OUTPUT -m state --state ESTABLISHED -j ACCEPT
 
# Blocks weird or broken connections that shouldn't exist (could be attacks or errors).
sudo iptables -A INPUT -m state --state INVALID -j DROP
 
# Allows SSH connections (so you can remotely access this machine via SSH on port 22).
sudo iptables -A INPUT -p tcp --dport 22 -m state --state NEW,ESTABLISHED -j ACCEPT
sudo iptables -A OUTPUT -p tcp --sport 22 -m state --state ESTABLISHED -j ACCEPT
 
# uncomment the following lines if want allow SSH into NVA only through the public subnet (app VM as a jumpbox)
# this must be done once the NVA's public IP address is removed
#sudo iptables -A INPUT -p tcp -s 10.0.2.0/24 --dport 22 -m state --state NEW,ESTABLISHED -j ACCEPT
#sudo iptables -A OUTPUT -p tcp --sport 22 -m state --state ESTABLISHED -j ACCEPT
 
# uncomment the following lines if want allow SSH to other servers using the NVA as a jumpbox
# if need to make outgoing SSH connections with other servers from NVA
#sudo iptables -A OUTPUT -p tcp --dport 22 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
#sudo iptables -A INPUT -p tcp --sport 22 -m conntrack --ctstate ESTABLISHED -j ACCEPT
 
# Allows one network (10.0.2.x) to talk to another (10.0.4.x) on port 27017 (MongoDB database).
sudo iptables -A FORWARD -p tcp -s 10.0.2.0/24 -d 10.0.4.0/24 --destination-port 27017 -m tcp -j ACCEPT
 
# Allows pinging (so one network can check if another is reachable).
sudo iptables -A FORWARD -p icmp -s 10.0.2.0/24 -d 10.0.4.0/24 -m state --state NEW,ESTABLISHED -j ACCEPT
 
# Blocks all incoming traffic unless you’ve explicitly allowed it (extra security).
sudo iptables -P INPUT DROP
 
# Blocks all forwarded traffic unless allowed (prevents unwanted network forwarding).
sudo iptables -P FORWARD DROP
 
echo "Done!"
echo ""
 
# make iptables rules persistent
# it will ask for user input by default
# Saves these firewall rules so they don’t reset after a reboot.
echo "Make iptables rules persistent..."
sudo DEBIAN_FRONTEND=noninteractive apt install iptables-persistent -y
echo "Done!"
echo ""


```
- Change permissions of the file:
  - `chmod +x config-ip-tables.sh`
  - `ls`
- Run the script:
  - `./config-ip-tables.sh`
  


## Edit DB NSG to make it more secure:
### Allow mongodb:
- Ip addresses
- 10.0.2.0/24
- Service- mongodb

![alt text](<../Images/Screenshot 2025-01-31 161133.png>)

### Deny everything else
- Change the destination port ranges to *.
- Number it 1000 so that it's easy to add allow rules above it.
- Add.

![alt text](<../Images/Screenshot 2025-01-31 160900.png>)


The ping from the app VM should stop after this rule is added.

You can allow the ping by creating a rule to allow the ping and making it come before the deny everything rule.

## Deleting Resources:

### Deleting VM's:
- Go to Virtual Machines-
- Filter for my name `zainab`
- Delete the VM's that appear (should be 3).

### Deleting Route Table:
- Go to Route Tables.
- Filter for my name `zainab`
- Click on it.
- Select subnets (associations) in the left tab.
- Disassociate the route table from the subnet.
- Go to overview and delete the route table.

### Deleting 3-subnet Vnet:
- Go to virtual networks.
- Delete 3-subnet vnet.
- May have to delete other resources under the vnet first and refresh to delete vnet.