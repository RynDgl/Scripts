#!/bin/bash

echo "timeout=300" >> /etc/yum.conf

yum update -y

yum install -y epel-release

sh /tmp/install-certs.sh

curl --location --max-time 900 https://dl.yarnpkg.com/rpm/yarn.repo | tee /etc/yum.repos.d/yarn.repo

curl --location --max-time 900 https://rpm.nodesource.com/setup_10.x | bash -

yum install -y yarn git gcc libX11-devel.x86_64 libxkbfile-devel.x86_64 libsecret-devel pkg-config
yum groupinstall -y 'Development Tools'
export PATH="$PATH:/opt/yarn*/bin"

yarn config set cafile /etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem

#set timeout to 16.66 minutes

cd /tmp/vscode-master

yarn --network-timeout 1000000
