# redis cluster

### 1. build images
```bash
docker build -t xh3b4sd/redis-cluster .
```

### 2. create masters
```bash
docker run -d --net=host --name=master-01 xh3b4sd/redis-cluster master 7001
docker run -d --net=host --name=master-02 xh3b4sd/redis-cluster master 7002
docker run -d --net=host --name=master-03 xh3b4sd/redis-cluster master 7003
```

### 3. join masters
```bash
docker run -it --rm --net=host dockerfile/redis redis-cli -c -p 7001 cluster meet 127.0.0.1 7002
docker run -it --rm --net=host dockerfile/redis redis-cli -c -p 7001 cluster meet 127.0.0.1 7003
```

### 4. create slots
```bash
docker run -it --rm --net=host dockerfile/redis /bin/sh -c "for i in $(eval 'echo {0..5500}'); do redis-cli -c -p 7001 cluster addslots \$i; done"
docker run -it --rm --net=host dockerfile/redis /bin/sh -c "for i in $(eval 'echo {5501..11000}'); do redis-cli -c -p 7002 cluster addslots \$i; done"
docker run -it --rm --net=host dockerfile/redis /bin/sh -c "for i in $(eval 'echo {11001..16383}'); do redis-cli -c -p 7003 cluster addslots \$i; done"
```

### 5. check state
```bash
docker run -it --rm --net=host dockerfile/redis redis-cli -c -p 7001 cluster info
cluster_state:ok
cluster_slots_assigned:16384
cluster_slots_ok:16384
...
cluster_known_nodes:3
cluster_size:3
...
```

### 6. create slaves
```bash
docker run -d --net=host --name=slave-01 xh3b4sd/redis-cluster slave 7004
docker run -d --net=host --name=slave-02 xh3b4sd/redis-cluster slave 7005
docker run -d --net=host --name=slave-03 xh3b4sd/redis-cluster slave 7006
```

### 7. join slaves
```bash
docker run -it --rm --net=host dockerfile/redis redis-cli -c -p 7004 slaveof 127.0.0.1 7001
docker run -it --rm --net=host dockerfile/redis redis-cli -c -p 7005 slaveof 127.0.0.1 7002
docker run -it --rm --net=host dockerfile/redis redis-cli -c -p 7006 slaveof 127.0.0.1 7003
```

### 8. write data
```bash
$ docker run -it --rm --net=host dockerfile/redis redis-cli -c -p 7001
127.0.0.1:7001> set foo bar
-> Redirected to slot [12182] located at 127.0.0.1:7003
OK
127.0.0.1:7001> get foo
"bar"
```

### 9. test failover
```bash
docker rm -f master-01
```



### xx. start and join slave again
```bash
docker run -d --net=host --name=slave-01 xh3b4sd/redis-cluster slave 7004
docker run -it --rm --net=host dockerfile/redis redis-cli -c -p 7004 slaveof 127.0.0.1 7001
```
