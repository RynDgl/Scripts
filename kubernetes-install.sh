#!/bin/bash

#assign IP
IP=`hostname -I | cut -d " " -f 1`
echo Enter Master or Worker node name:
read NODENAME
echo "What type of node are you installing?"
select NODETYPE in "MASTER" "WORKER"; do
    case $NODETYPE in
        MASTER ) NODETYPE=MASTER; break;;
        WORKER ) NODETYPE=WORKER; exit;;
    esac
done

#add more hosts if needed example would be other nodes
echo >> /etc/hosts $IP $NODENAME 

#configure networking
if [$NODETYPE == "MASTER"]
then
# MASTER NODE
# TCP	Inbound	6443*	Kubernetes API server	All
firewall-cmd --zone=public --add-port=6443/tcp --permanent
# TCP	Inbound	2379-2380	etcd server client API	kube-apiserver, etcd
firewall-cmd --zone=public --add-port=2379-2380/tcp --permanent
# TCP	Inbound	10250	Kubelet API	Self, Control plane
firewall-cmd --zone=public --add-port=10250/tcp --permanent
# TCP	Inbound	10251	kube-scheduler	Self
firewall-cmd --zone=public --add-port=10251/tcp --permanent
# TCP	Inbound	10252	kube-controller-manager	Self
firewall-cmd --zone=public --add-port=10252/tcp --permanent
else
# WORKER NODE
# TCP	Inbound	10250	Kubelet API	Self, Control plane
firewall-cmd --zone=public --add-port=10250/tcp --permanent
# TCP	Inbound	30000-32767	NodePort Services**	All
firewall-cmd --zone=public --add-port=30000-32767/tcp --permanent
fi

firewall-cmd --reload

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

#mkdir -p /etc/systemd/system/docker.service.d (maybe not needed)

#retart docker
systemctl daemon-reload
systemctl restart docker
systemctl enable docker.service

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
systemctl enable kubelet

#initialize kubernetes cluster REPLACE ADDRESS WITH APPROPRIATE ADDRESS FOR NODE
if [$NODETYPE == "MASTER"]
then
    kubeadm init --apiserver-advertise-address=$IP --pod-network-cidr=192.168.1.0/16
elif [$NODETYPE == "WORKER"]
    echo Enter your join token
    read JOINTOKEN  
    do ;
    #add a scan of token to add the master to host list
    echo Joining Master
    $JOINTOKEN
    done
fi



#configure kubernetes
mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config

#deploy flannel network to cluster
kubectl apply -f \
https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml

#set node ip static (for private network or testing)
#