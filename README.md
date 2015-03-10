# redis cluster

### show help
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
    info              show cluster information
```
