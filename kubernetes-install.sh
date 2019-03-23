#!/bin/bash

#add more hosts if needed example would be other nodes
echo >> /etc/hosts 192.168.1.99 kubemaster

#turn off SELinux
setenforce 0
sed -i --follow-symlinks 's/SELINUX=enforcing/SELINUX=disabled/g' \
/etc/sysconfig/selinux

#turn off Swap
swapoff -a
#(in progress edit /etc/fstab ) sed 's/^' /etc/fstab

#enable br_netfilter
modprobe br_netfilter
echo '1' > /proc/sys/net/bridge/bridge-nf-call-iptables

#install docker dependencies
yum install -y yum-utils device-mapper-persistent-data lvm2 
wget http://mirror.centos.org/centos/7.6.1810/extras/x86_64/Packages/container-selinux-2.74-1.el7.noarch.rpm
yum localinstall -y container-selinux-2.74-1.el7.noarch.rpm
rm container-selinux-2.74-1.el7.noarch.rpm

#add docker-ce repo
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

#install docker
yum install -y docker-ce

#configure docker daemon
cat > /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2",
  "storage-opts": [
    "overlay2.override_kernel_check=true"
  ]
}
EOF

mkdir -p /etc/systemd/system/docker.service.d

#retart docker
systemctl daemon-reload
systemctl restart docker

#configure Kubernetes
cat >> /etc/yum.repos.d/kubernetes.repo <<EOF
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg
        https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF

#install kubernetes
yum install -y kubelet kubeadm kubectl

#add kubernetes to same cgroup as docker "cgroupfs"
sed -i 's/cgroup-driver=systemd/cgroup-driver=cgroupfs/g' \
/etc/systemd/system/kubelet.service.d/10-kubeadm.conf

#restart systemd daemon and kubelet service
systemctl daemon-reload
systemctl restart kubelet

#initialize kubernetes cluster REPLACE ADDRESS WITH APPROPRIATE ADDRESS FOR NODE
kubeadm init --apiserver-advertise-address=192.168.1.99 \
--pod-network-cidr=192.168.1.0/16

#configure kubernetes
mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config

#deploy flannel network to cluster
kubectl apply -f \
https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml