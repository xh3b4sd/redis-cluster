# redis cluster

### usage
```bash
$ ./cluster help
test redis cluster using multiple docker containers

COMMANDS:
    create            create a test cluster using multiple docker containers
    stop              stop all cluster related docker containers
    build             build the necessary docker image
    connect [port]    connect to a redis-cli to interact to the cluster
    failover          test failover by removing a master node from the cluster
    join              join a new node to the cluster after failover to replicate
    info              show cluster info
    nodes             show cluster nodes
```

### playground

##### build image

The first thing we need to do, is to build the docker image. After doing so we can start playing around.

```bash
$ ./cluster build
<be patient here>
```

##### create cluster

The following command creates the minimum required cluster existing of 3 master
and 3 slave nodes.

```bash
$ ./cluster create
create members
4f9d72c037730d552ec5066927650bb718bbaa6ae197ca1841be233869f7efef
2f0ce7a2aded8e8f27cc60cf9a38ca78bce792238553bdbd5a819c8b7b5823fd
417b0d325527b646dddbad357775f5a809064c6d0125880ef60a4e449419c326
47f3efc564c208ae111ff92261c19a5e23ece929aa28f89c4cf801e40684bb2f
336cf463574d023d4bf6c7b1e973c3ff3a6c72e2fe14711e13ae31c92095e7fa
ebb2e092725e367fd9412ae598ffc7a6938b86d3b28d5bff61b25cb92bc9f604
join members
OK
OK
OK
OK
OK
create slots
<be patient here>
replicate masters
OK
OK
OK
```

##### check cluster

Next we want to verify the state of the cluster we just created. When everything
went fine, you should see something like the following output.

```bash
# check cluster info
$ ./cluster info
cluster_state:ok
cluster_slots_assigned:16384
cluster_slots_ok:16384
cluster_slots_pfail:0
cluster_slots_fail:0
cluster_known_nodes:6
cluster_size:3
cluster_current_epoch:5
cluster_my_epoch:1
cluster_stats_messages_sent:743
cluster_stats_messages_received:743

# check cluster nodes
$ ./cluster nodes
d361fe230eb2007dd8391d5377524e686c2b5b30 127.0.0.1:7004 slave ee69087246692d722ca5912671dfa466ef12b193 0 1426000827737 5 connected
ee69087246692d722ca5912671dfa466ef12b193 127.0.0.1:7001 master - 0 1426000828244 0 connected 0-5500
dbdd8652832041df83ab16d73b0e6c8070e7eafc 127.0.0.1:7005 slave 85480019ccef43d5b56f6fb7de4f631ceb04ffff 0 1426000828244 2 connected
46a425d44e5ae925a034a34537ef70a957339944 127.0.0.1:7003 master - 0 1426000826722 3 connected 11001-16383
2f6e8c5b1a0968c99d24a74e52bff5def6191ab9 127.0.0.1:7006 slave 46a425d44e5ae925a034a34537ef70a957339944 0 1426000827737 4 connected
85480019ccef43d5b56f6fb7de4f631ceb04ffff 127.0.0.1:7002 myself,master - 0 0 1 connected 5501-11000
```

##### read/write data

Here we write some data to the cluster to ensure it is distributed accross all
nodes.

```bash
# write data
$ ./cluster connect 7002
127.0.0.1:7002> set foo bar
-> Redirected to slot [12182] located at 127.0.0.1:7003
OK

# read data
$ ./cluster connect 7001
127.0.0.1:7001> get foo
-> Redirected to slot [12182] located at 127.0.0.1:7003
"bar"
```

##### test failover

Now we remove one master node from the cluster by just removing the docker
container of `master-01`. This should cause its slave to win the master
election, to finally become the new master taking care of all hash slots
`master-01` was responsible for.

```bash
# remove docker container
$ ./cluster failover
master-01
```

##### check cluster again

To verify the cluster is still alive we need to check the cluster state again.
In case the redis cluster was able to tollerate the node failure of the
previous step, should still see `cluster_state:ok`.

Further we should see `master,fail` when checking the cluszer nodes again. Also
note that the node with port `7004` (slave), just turned into a master due to
the failover.

```bash
# check cluster info
$ ./cluster info
cluster_state:ok
cluster_slots_assigned:16384
cluster_slots_ok:16384
cluster_slots_pfail:0
cluster_slots_fail:0
cluster_known_nodes:6
cluster_size:3
cluster_current_epoch:6
cluster_my_epoch:1
cluster_stats_messages_sent:9640
cluster_stats_messages_received:7957

# check cluster nodes
$ ./cluster nodes
d361fe230eb2007dd8391d5377524e686c2b5b30 127.0.0.1:7004 master - 0 1426004359298 6 connected 0-5500
ee69087246692d722ca5912671dfa466ef12b193 127.0.0.1:7001 master,fail - 1426004184553 1426004182119 0 disconnected
dbdd8652832041df83ab16d73b0e6c8070e7eafc 127.0.0.1:7005 slave 85480019ccef43d5b56f6fb7de4f631ceb04ffff 0 1426004357778 2 connected
46a425d44e5ae925a034a34537ef70a957339944 127.0.0.1:7003 master - 0 1426004358282 3 connected 11001-16383
2f6e8c5b1a0968c99d24a74e52bff5def6191ab9 127.0.0.1:7006 slave 46a425d44e5ae925a034a34537ef70a957339944 0 1426004359298 4 connected
85480019ccef43d5b56f6fb7de4f631ceb04ffff 127.0.0.1:7002 myself,master - 0 0 1 connected 5501-11000
```

##### check data

Now that the cluster successfully survived a node failure, we are still be able
to fetch our data.

```bash
# check if data is available on an old master
$ ./cluster connect 7002
127.0.0.1:7002> get foo
-> Redirected to slot [12182] located at 127.0.0.1:7003
"bar"

# check if data is available on the new master
$ ./cluster connect 7004
127.0.0.1:7004> get foo
-> Redirected to slot [12182] located at 127.0.0.1:7003
"bar"
```

##### join node

The cluster just survided one node failure. In case `slave-04` (the new master)
dies, the whole cluster will die. So lets join a new node to the cluster and
let it replicate hash slots of `slave-04`, to make the cluster fault tollerant
again.

```bash
$ ./cluster join
create new node
0d0ff65f11928afa422327f9df7066f4153f6cd74113582e05480cf5392ba1b9
OK
replicate failover
OK
```

##### check cluster again

A new node joined the cluster. Lets check the current state. The cool thing we
now should see is this `127.0.0.1:7004 master`. Also the node we just joined
(listening on `7001`), is now replicating for `slave-04`.

```bash
# check cluster info
$ ./cluster info
cluster_state:ok
cluster_slots_assigned:16384
cluster_slots_ok:16384
cluster_slots_pfail:0
cluster_slots_fail:0
cluster_known_nodes:7
cluster_size:3
cluster_current_epoch:6
cluster_my_epoch:1
cluster_stats_messages_sent:1129
cluster_stats_messages_received:1039

# check cluster nodes
$ ./cluster nodes
914001ecf73f14dba874bd808e793b49a235d6d7 127.0.0.1:7005 slave 9bbbdf24336d791c9585310819d72069b167862a 0 1426005061513 3 connected
87650f26d3e41321a4cc172b275f1159cf72a95f 127.0.0.1:7003 master - 0 1426005062018 4 connected 11001-16383
c58e895798a2b1c28c1947f15d6f002d8906b8d5 127.0.0.1:7001 slave 9581406e991c371ec83a33c83f472220bc62143d 0 1426005061005 6 connected
36a6aff32d7689f23b3a93eb93a4508b7d5249a4 127.0.0.1:7006 slave 87650f26d3e41321a4cc172b275f1159cf72a95f 0 1426005059996 5 connected
9581406e991c371ec83a33c83f472220bc62143d 127.0.0.1:7004 master - 0 1426005062018 6 connected 0-5500
9bbbdf24336d791c9585310819d72069b167862a 127.0.0.1:7002 myself,master - 0 0 1 connected 5501-11000
c18149f6a88f2e0e71f7105b7c6b6ad5c4aab8b8 :0 master,fail,noaddr - 1426004903123 1426004902113 0 disconnected
```
