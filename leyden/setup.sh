#!/bin/bash
set -ex

# https://github.com/sdeleuze/spring-boot-leyden-demo/blob/main/image/setup.sh
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y --no-install-recommends tzdata ca-certificates git curl build-essential libfreetype6-dev libfontconfig-dev libcups2-dev libx11-dev libxext-dev libxrender-dev libxrandr-dev libxtst-dev libxt-dev libasound2-dev libffi-dev autoconf file unzip zip nano

export BOOT_JDK_URL="https://download.bell-sw.com/java/23.0.1+13/bellsoft-jdk23.0.1+13-linux-amd64.tar.gz";
mkdir -p /opt/boot-jdk
cd /opt/boot-jdk
curl -L ${BOOT_JDK_URL} | tar zx --strip-components=1
test -f /opt/boot-jdk/bin/java
test -f /opt/boot-jdk/bin/javac

cd /opt
git clone -b premain --depth 1 https://github.com/openjdk/leyden.git
cd leyden

bash configure --with-boot-jdk=/opt/boot-jdk
make images
mv /opt/leyden/buildlinux-x86_64-server-release/images/jdk /opt
