How to deploy an app with high availability and scalability:
- Using a VMSS
- Spreading VM's accross 3 zones.
- Minimum of 2 VMs.

# Creating a monitoring and alerts dashboard

- Go to the overview page of vm.
- Monitoring tab.
  - Can see the graphs by default through azure monitor (similar to cloudwatch on AWS).
  - We want to turn these charts into a dashboard.

1. In the monitoring tab for the vm- scroll down to where you can see the charts.
2. Click the pin on the CPU average graph:
   - Create new.
   - Shared type
   - Name:tech501-zainab-shared-app-dashboard
   - Click create and pin.
1. Add the network total metric and the disk operations to the dashboard you just created.

To view the dashboard:
1. Go to `Dashboard hub`.
2. 2.Click on your dashboard.
3. Click `Go to dashboard` at the top.

Can change the size and layout of the dashboard by clicking edit. Press Edit and then `x` on the tile popup.

If you click on the metric, can change the time frame and then click save to dashboard (might not work if you change time frame without clicking the metric).

## Installing Apache Bench (load testing)
- `sudo apt-get install apache2-utils`
- `ab -n 1000 -c 100 http://yourwebsite.com/`
- `ab -n 1000 -c 100 http://4.234.1.191/`

Increases CPU usage by sending load to the application- doesn't represent a real application.

## Alerts

- Go to Alerts in azure console.
- Or go to the vm monitoring section. 
- Create alert group (action group).
- Email alert notifications. 
- Change CPU metrics- CPU greater than 30.
- Critical 

![alt text](<../Images/Screenshot 2025-02-04 171123.png>)
![alt text](<../Images/Screenshot 2025-02-04 171109.png>)
![alt text](<../Images/Screenshot 2025-02-04 171147.png>)

# Auto Scaling

## Why use autoscaling:

Worst to better: When CPU load is too high
1. Fall over (worst option)
2. dashbord
3. alert- e.g. alarms going off at 3.5% cpu usage.
   - for testing purposes. Generally it's 40%.
4. autoscaling (best option)

### Types of scaling:
1. Horizontal scaling (in or out) (more instances).
2. Vertical scaling (up or down) (more CPU, RAM etc).

### Azure Virtual machine scale sets (VMSS)

- Same as aws autoscaling group
- **High availability and scalability** and making application reliable!
- Custom autoscale:
  - When CPU exceeds 75%
  - Start with 2 VMs:
    - Disaster recovery plan, redundancy, high availablity.
  - Minimum 2
  - Default 2 
  - Maximum 3  
  - Put the VM's into different zones to ensure high availability and redundancy:
    - Zone 1, 2, 3.
- The VMSS will create the VM's from the images given to it.
- Traffic enters through internet- load balancer will recieve the traffic and balance it accross VM's.


- If VM image is created with userdata, and you use that image for the VMSS, when you stop vm, and restart it, status will show as unhealthy because the userdata only works initially and app won't be accessible after restart.

- Reimage= User data runs again and VM is returned to initial state- everything else is deleted.


## Creating a VMSS:
- Name: tech501-zainab-sparta-app-vmss
- AZ: Zone 1, 2, 3
- Orchestration mode: Uniform
- Security type: Standard
- Scaling mode: Autoscaling
    - Configure- click the edit button
    - Min=2, Max=3, Default=2
    - Scale out= CPU threshold 75%
    - Save
- Image: See all images- my images- select your own app image.
- SSH key- select existing key on azure- select your own key.
- OS disk type- Standard SSD
- PublicIp: Disabled (don't need one because we will access VM through load balancer).
- Frontend port range start: 50000 (ssh to port 50000 to reach first vm, incrementing by one for the next etc)
- Backend port: 22
- Load Balancer: Create a new load balancer
    - Name: tech501-zainab-app-lb
    - Need to connect to our VM's through port 50000 upwards e.g. 1st VM SSH will be through port 50000, - 2nd through 50001 etc.
- Enable health monitoring.
- Enable automatic repairs.
- Enable User data and paste in the script:
```
#!/bin/bash
cd /repo/app
pm2 start app.js

```
![alt text](../Images/Diagram.png)



- Enter public IP of the VMSS into the browser- should show app page.
  - Might take a few mins.
- **When you restart vm** (stop and start vm), need to reimage atleast 1 vm for the app to work. 
  - This is because the image user data for the vm only runs the first time and the app won't start up everytime after that.
  - Reimaging means the userdata runs again from scratch and the vm is replaced.

Health status is only healthy or unhealthy if the vm is running. Blank if not running.

### SSH into the VM:

- No public Ip and can't go through private Ip (not in the same vnet) so have to go in through the load balancer.
- So use load balancer IP.
- `ssh -i ~/.ssh/tech501-zainab-az-key -p 50000 adminuser@85.210.45.236`
  - `-p 50000` specifies the port that we use to SSH into the vm- specified in the vmss settings.

### Deleting the VMSS:
- Go to VMSS- Delete option at the top.
- Have to delete load balancer separately. 
  - Go to load balancers.
  - Delete.