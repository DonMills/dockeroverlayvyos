# dockeroverlayvagrant
This is a vagrant and chef repo that will create a master etcd server
with the latest docker installed, and then create n+1 minion docker servers
preconfigured to use the etcd master and running in etcd proxy mode.

<h2> Usage </h2>
The first step is to edit the vagrantfile to determine the number of minions desired,
and whether you want the virtualbox provider to open a console window for each server.
The defaults are one minion, and true on the console display.
```
MINION_COUNT = 1
GUI = true
```
Then issue a ```vagrant up```, and go get a cold drink...

<h2> Initial Verification </h2>
To test that etcd is functioning on the hosts, ssh to any one of them (or use the
console if you left that as default) and issue:
```
etcdctl cluster-health
```
You should see a similar response on any of the servers:
```
vagrant@etcdmaster:~$ etcdctl cluster-health
member 1dcf27d122fb08cb is healthy: got healthy result from http://192.168.2.15:2379
cluster is healthy
```
Then you can test docker integration with etcd by getting on any of the servers and
creating a docker overlay network:
```
vagrant@etcdmaster:~$ docker network create --driver=overlay --subnet=192.168.50.0/24 net1
bd5aae60c3977bc3ed533b603212f20b7bb0692cd40d760c74c7bd13f608158b
vagrant@etcdmaster:~$ docker network ls
NETWORK ID          NAME                DRIVER
bd5aae60c397        net1                overlay             
e7a4151b815f        bridge              bridge              
58ba54bccdfa        none                null                
82045ce06067        host                host            
```
You can see the net1 overlay network created.
Check from another host:
```
vagrant@minion0:~$ docker network ls
NETWORK ID          NAME                DRIVER
bd5aae60c397        net1                overlay             
44c3b94009e7        bridge              bridge              
419e4cbf360b        none                null                
eab10f643026        host                host  
```
And that looks good...Now all that's left is firing up some docker containers.
```
vagrant@minion0:~$ docker run -it --net=net1 --name mintest busybox
```
and
```
vagrant@etcdmaster:~$ docker run -it --net=net1 --name mastest busybox
```
and run a ping! (this is from the minion0 host, container "mintest"
```
/ # ping mastest
PING mastest (192.168.50.3): 56 data bytes
64 bytes from 192.168.50.3: seq=0 ttl=64 time=1.125 ms
64 bytes from 192.168.50.3: seq=1 ttl=64 time=0.471 ms
64 bytes from 192.168.50.3: seq=2 ttl=64 time=0.481 ms
64 bytes from 192.168.50.3: seq=3 ttl=64 time=0.448 ms
```
BAM -> you are pinging over a vxlan tunnel between hosts.



