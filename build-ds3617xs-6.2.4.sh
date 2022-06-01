#!/bin/bash

# prepare build tools
sudo apt-get update && sudo apt-get install --yes --no-install-recommends ca-certificates build-essential git libssl-dev curl cpio bspatch vim gettext bc bison flex dosfstools kmod jq

root=`pwd`
mkdir DS3617xs-6.2.4
mkdir output
cd DS3617xs-6.2.4

# download redpill
git clone --depth=1 https://github.com/RedPill-TTG/redpill-lkm.git
git clone --depth=1 https://github.com/RedPill-TTG/redpill-load.git

# download syno linux kernel
curl --location "https://sourceforge.net/projects/dsgpl/files/Synology%20NAS%20GPL%20Source/25426branch/broadwell-source/linux-3.10.x.txz/download" --output linux-3.10.x.txz

# build redpill-lkm
cd redpill-lkm
tar -xf ../linux-3.10.x.txz
cd linux-3.10*
linuxsrc=`pwd`
cp synoconfigs/broadwell .config
sed -i 's/   -std=gnu89/   -std=gnu89 -fno-pie/' Makefile
make oldconfig ; make modules_prepare
cd ..
make LINUX_SRC=${linuxsrc} test-v6
read -a KVERS <<< "$(sudo modinfo --field=vermagic redpill.ko)" && cp -fv redpill.ko ../redpill-load/ext/rp-lkm/redpill-linux-v${KVERS[0]}.ko || exit 1
cd ..

# build redpill-load
cd redpill-load
cp -f ${root}/user_config.DS3617xs.json ./user_config.json
./ext-manager.sh add https://raw.githubusercontent.com/pocopico/rp-ext/master/r8168/rpext-index.json
sudo ./build-loader.sh 'DS3617xs' '6.2.4-25556'
mv images/redpill-DS3617xs_6.2.4-25556*.img ${root}/output/
cd ${root}
