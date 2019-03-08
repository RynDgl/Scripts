#!/bin/bash/

#Docker Install and configuration script

#Remove old installations
yum remove docker \
                  docker-client \
                  docker-client-latest \
                  docker-common \
                  docker-latest \
                  docker-latest-logrotate \
                  docker-logrotate \
                  docker-engine

#install required binaries
yum install -y yum-utils \
  device-mapper-persistent-data \
  lvm2 \
  wget
  
#Add Docker repo
yum-config-manager \
    --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo
    
#Install container-SELinux
wget http://mirror.centos.org/centos/7.6.1810/extras/x86_64/Packages/container-selinux-2.74-1.el7.noarch.rpm
yum localinstall -y container-selinux-2.74-1.el7.noarch.rpm

#Install Docker
yum install -y docker-ce docker-ce-cli containerd.io

#Configure Docker to run on boot
systemctl enable docker.service

#Configure Docker Daemon
touch /etc/docker/daemon.json
printf '%s\n' '{' '"hosts": ["unix:///var/run/docker.sock"]' '}' >> /etc/docker/daemon.json

#Test Docker
dockerd
docker run hello-world

