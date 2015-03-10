# This tag use ubuntu 14.04
FROM phusion/baseimage:0.9.15

ENV HOME /root

RUN /etc/my_init.d/00_regen_ssh_host_keys.sh

# Some Environment Variables
ENV DEBIAN_FRONTEND noninteractive

# # Ensure UTF-8 lang and locale
RUN locale-gen en_US.UTF-8
ENV LANG       en_US.UTF-8
ENV LC_ALL     en_US.UTF-8

# Initial update and install of dependency that can add apt-repos
RUN apt-get -y update && apt-get install -y software-properties-common python-software-properties

# Add global apt repos
RUN add-apt-repository -y "deb http://archive.ubuntu.com/ubuntu precise universe" && \
    add-apt-repository -y "deb http://archive.ubuntu.com/ubuntu precise main restricted universe multiverse" && \
    add-apt-repository -y "deb http://archive.ubuntu.com/ubuntu precise-updates main restricted universe multiverse" && \
    add-apt-repository -y "deb http://archive.ubuntu.com/ubuntu precise-backports main restricted universe multiverse"
RUN apt-get update && apt-get -y upgrade

# Install system dependencies
RUN apt-get install -y gcc make g++ build-essential libc6-dev tcl git

# checkout the 3.0 (Cluster support) branch from official repo
RUN git clone -b 3.0 https://github.com/antirez/redis.git

# Build redis from source
RUN (cd /redis && make)

RUN mkdir -p /var/run/redis/

ADD ./main.sh /var/run/redis/main.sh
ADD ./redis_master.conf /var/run/redis/redis_master.conf
ADD ./redis_slave.conf /var/run/redis/redis_slave.conf

ENTRYPOINT [ "/var/run/redis/main.sh" ]
