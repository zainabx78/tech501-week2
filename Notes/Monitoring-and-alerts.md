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
