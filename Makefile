build:
	docker build -t xh3b4sd/redis-cluster .

start:
	@# create masters
	docker run -d --net=host --name=master-01 xh3b4sd/redis-cluster master 7001
	docker run -d --net=host --name=master-02 xh3b4sd/redis-cluster master 7002
	docker run -d --net=host --name=master-03 xh3b4sd/redis-cluster master 7003
	@# join masters
	docker run -it --rm --net=host dockerfile/redis redis-cli -c -p 7001 cluster meet 127.0.0.1 7002
	docker run -it --rm --net=host dockerfile/redis redis-cli -c -p 7001 cluster meet 127.0.0.1 7003
	@# create slots
	docker run -it --rm --net=host dockerfile/redis /bin/sh -c "for i in $(eval 'echo {0..5500}'); do redis-cli -c -p 7001 cluster addslots \$i; done"
	docker run -it --rm --net=host dockerfile/redis /bin/sh -c "for i in $(eval 'echo {5501..11000}'); do redis-cli -c -p 7002 cluster addslots \$i; done"
	docker run -it --rm --net=host dockerfile/redis /bin/sh -c "for i in $(eval 'echo {11001..16383}'); do redis-cli -c -p 7003 cluster addslots \$i; done"
	@# create slaves
	docker run -d --net=host --name=slave-01 xh3b4sd/redis-cluster slave 7004
	docker run -d --net=host --name=slave-02 xh3b4sd/redis-cluster slave 7005
	docker run -d --net=host --name=slave-03 xh3b4sd/redis-cluster slave 7006
	@# join slaves
	docker run -it --rm --net=host dockerfile/redis redis-cli -c -p 7004 slaveof 127.0.0.1 7001
	docker run -it --rm --net=host dockerfile/redis redis-cli -c -p 7005 slaveof 127.0.0.1 7002
	docker run -it --rm --net=host dockerfile/redis redis-cli -c -p 7006 slaveof 127.0.0.1 7003
	@# TODO migrate slots

stop:
	docker rm -f master-01
	docker rm -f master-02
	docker rm -f master-03
	docker rm -f slave-01
	docker rm -f slave-02
	docker rm -f slave-03
