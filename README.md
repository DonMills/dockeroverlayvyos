# dockeroverlayvyos
This is a vagrant and chef repo that will create a master etcd server
with the latest docker installed on one subnet, and then create n+1 minion docker servers
preconfigured to use the etcd master and running in etcd proxy mode on a second subnet.  This vagrant repo will also create a vyos (vyatta) based software router in between the etcd master server and the minions to demonstrate layer 3 overlay features. The vyos router has ip flow accounting pre-enabled on the two interfaces facing the docker host networks so you can see the vxlan traffic flowing between them.

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
First you can check the ip addresses and routes on the docker hosts to show the layer 3 topology:

```
vagrant@etcdmaster:~$ ip addr
...
3: eth1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000
    link/ether 08:00:27:18:8a:35 brd ff:ff:ff:ff:ff:ff
    inet 192.168.2.15/24 brd 192.168.2.255 scope global eth1
       valid_lft forever preferred_lft forever
    inet6 fe80::a00:27ff:fe18:8a35/64 scope link 
       valid_lft forever preferred_lft forever
...
vagrant@etcdmaster:~$ ip route
...
192.168.30.0/24 via 192.168.2.1 dev eth1 
...
```
and

```
vagrant@minion0:~$ ip addr
...
3: eth1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000
    link/ether 08:00:27:c9:a3:55 brd ff:ff:ff:ff:ff:ff
    inet 192.168.30.200/24 brd 192.168.30.255 scope global eth1
       valid_lft forever preferred_lft forever
    inet6 fe80::a00:27ff:fec9:a355/64 scope link 
       valid_lft forever preferred_lft forever
...
vagrant@minion0:~$ ip route
... 
192.168.2.0/24 via 192.168.30.1 dev eth1 
```
192.168.2.1 and 192.168.30.1 are the ip addresses of the vyos router eth1 and eth2 respectively.

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

If you want to see the traffic crossing through the router between the two "physical" networks you can get on the vyos box and issue the following command:
```
vagrant@vyos:~$ sh flow-account
flow-accounting for [eth1]
Src Addr        Dst Addr        Sport Dport Proto    Packets      Bytes   Flows
192.168.2.15    192.168.30.200  7946  7946    udp       1022      48148       1
192.168.2.15    192.168.30.200  42129 4789    udp        183      24522       1
192.168.2.15    192.168.30.200  2379  41456   tcp         37      23598       1
192.168.2.15    192.168.30.200  2379  41440   tcp         26      16122       1
192.168.2.15    192.168.30.200  2379  41438   tcp         26      11782       1
```




