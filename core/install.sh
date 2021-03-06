#!/bin/bash

# Copyright 2010 Todd Deshane <deshantm@gmail.com>
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.

cd `dirname $0`

#detect supported platforms
release=`grep DISTRIB_RELEASE /etc/lsb-release  | awk -F\= '{ print $2}'` 
if [ X$release != X9.04 ] && [ X$release != X9.10 ] && [ X$release != X10.04 ] && [ X$release != X10.10 ]
then
    echo 'Ubuntu is the only tested and supported platform for this release'
    exit 1
fi

#install deps
echo -n 'Installing dependencies... '
sudo apt-get install -y qemu ubuntu-virt-mgmt 

#install deps specific to development and testing
#sudo apt-get install -y nautilus-open-terminal emacs openssh-server denyhosts

#TODO reconfigure ssh server and denyhosts on the fly

echo 'Done'

#patch vmbuilder due to bugs
#echo -n 'Patching vmbuilder (fixing bugs in vmbuilder)... '
#sudo patch -p0 -N < ./patches/vmbuilder.patch
#sudo patch -p0 -N < ./patches/jdstrand.patch
#sudo patch -p0 -N < ./patches/jdstrand2.patch
#echo 'Done'

#install OSCKARcore
echo -n 'Installing OSCKARcore-alpha... '
sudo useradd eventchat -r -s /bin/sh
sudo useradd policymanager -r -s /bin/sh
sudo useradd vmminterface -r -s /bin/sh
sudo useradd builderinterface -r -s /bin/sh
sudo groupadd osckaradmins

#add vmminterface to libvirtd group
sudo usermod -G libvirtd vmminterface

#make installable/clean distribution of osckar
rm -rf ./dist
mkdir -p ./dist/usr/sbin/
mkdir -p ./dist/usr/share/
mkdir -p ./dist/etc/
mkdir -p ./dist/var/lib/
mkdir -p ./dist/var/log/
mkdir -p ./dist/var/run/
mkdir -p ./dist/var/lib/osckar/images/

sudo cp -rp ./usr/sbin/* ./dist/usr/sbin/
sudo cp -rp ./usr/share/* ./dist/usr/share/
sudo cp -rp ./etc/* ./dist/etc/
sudo cp -rp ./var/lib/* ./dist/var/lib/
sudo cp -rp ./var/log/* ./dist/var/log/
sudo cp -rp ./var/run/* ./dist/var/run/

#clean dist
sudo find ./dist/ -name '*~' -exec rm {} \;
find ./dist/ -name '.svn' -exec rm -rf {} \; > /dev/null 2>&1

#install from dist
sudo cp -rp ./dist/usr/sbin/* /usr/sbin/
sudo cp -rp ./dist/usr/share/* /usr/share/
sudo cp -rp ./dist/etc/* /etc/
sudo cp -rp ./dist/var/lib/* /var/lib/
sudo cp -rp ./dist/var/log/* /var/log/
sudo cp -rp ./dist/var/run/* /var/run/

#access to contracts
sudo chown -R policymanager /var/lib/policymanager
sudo chown -R vmminterface /var/lib/osckar/interfaces/vmm

#access to log directories
sudo chown -R eventchat /var/log/eventchat
sudo chown -R policymanager /var/log/policymanager
sudo chown -R vmminterface /var/log/osckar/vmminterface
sudo chown -R builderinterface /var/log/osckar/builderinterface

#access to (/var/run) pid directories
sudo chown -R eventchat /var/run/eventchat
sudo chown -R policymanager /var/run/policymanager
sudo chown -R vmminterface /var/run/osckar/vmminterface
sudo chown -R builderinterface /var/run/osckar/builderinterface

#access to (/var/lib/osckar/images) VM base image directories
sudo chown -R builderinterface:osckaradmins /var/lib/osckar/images/
sudo chmod -R g+w /var/lib/osckar/images/

#give builderinterface the access it needs to run vmbuilder without entering a 
#password
sudo grep builderinterface /etc/sudoers
if [ $? -eq 1 ]; then
    echo 'builderinterface ALL=NOPASSWD: /usr/bin/vmbuilder' | sudo tee -a /etc/sudoers > /dev/null 2>&1
fi
echo 'Done'

