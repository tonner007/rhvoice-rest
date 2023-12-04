#!/bin/bash

if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

RUNTIME_PACKAGES="lame python3 python3-setuptools locales opus-tools flac locales-all"
BUILD_PACKAGES="git scons python3-pip python3-wheel python3-lxml build-essential libspeechd-dev pkg-config"

apt-get update -y
apt-get -y install --no-install-recommends "${RUNTIME_PACKAGES}" "${BUILD_PACKAGES}"
sudo -H python3 -m pip install -r requirements.txt

cp app.py /opt/rhvoice-rest.py
cp rhvoice_rest_cache.py /opt/
chmod +x /opt/rhvoice-rest.py

git clone --recurse-submodules --depth=1 --branch 1.14.0 https://github.com/RHVoice/RHVoice /opt/RHVoice
cd /opt/RHVoice && scons && scons install && ldconfig

git clone https://github.com/vantu5z/RHVoice-dictionary.git /opt/RHVoice-dictionary
mkdir -p /usr/local/etc/RHVoice/ && mkdir -p /opt/data
cp -R /opt/RHVoice-dictionary/dicts /usr/local/etc/RHVoice/dicts
cp -R /opt/RHVoice-dictionary/tools/preprocessing /opt/rhvoice_tools
cd /opt && rm -rf /opt/RHVoice /opt/RHVoice-dictionary

{
echo '[Unit]'
echo 'Description=RHVoice REST API'
echo 'After=network.target'
echo '[Service]'
echo 'ExecStart=/opt/rhvoice-rest.py'
echo 'Restart=always'
echo 'User=root'
echo '[Install]'
echo 'WantedBy=multi-user.target'
} > /etc/systemd/system/rhvoice-rest.service

systemctl enable rhvoice-rest.service
systemctl start rhvoice-rest.service
