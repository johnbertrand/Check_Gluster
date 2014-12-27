Check_Gluster
=============

#Gluster Check Plugin#
Nagios health check for GlusterFS 3.3.  It checks a volumes status, and if all the bricks are present.

#CLI Usage#
```
nagios@monitor:~/> ./check_gluster.pl -v data -n 2
GLUSTER OK - Volume data is Stable
```
Where -v is the volume name, and -n is the expected number of bricks.

#Called via NRPE#
```
nagios@monitor:~/> ./check_nrpe -H 10.4.20.69 -c check_gluster
```

#Deployment#
Add to nrpe.cfg.
````
command[check_gluster]=/usr/local/nagios/libexec/check_gluster.pl -v data -n 4 
````
The script wraps a call to gluster, and that command needs to be run as root, 
so you might need to add something similar to your sudoers.
````
nagios ALL=NOPASSWD:/usr/sbin/gluster volume info data
````
Put this in command.cfg on your nagios server.
````
define command{ command_name check-gluster-status command_line $USER1$/check_nrpe -H $HOSTADDRESS$ -c check_gluster }
````
Define the service, and you're done.
````
define service{ 
       use generic-service 
     hostgroup_name gluster-hosts
     service_description gluster_status
     check_command check-gluster-status
     notifications_enabled 0
     }
````







