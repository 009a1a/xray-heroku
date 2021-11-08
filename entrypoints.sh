#! /bin/bash
set -ex
if [[ -z "${VER}" ]]; then
  VER="latest"
fi
echo ${VER}

if [[ -z "${Vless_Path}" ]]; then
  Vless_Path="/s233"
fi
echo ${Vless_Path}

if [[ -z "${Vless_UUID}" ]]; then
  Vless_UUID="5c301bb8-6c77-41a0-a606-4ba11bbab084"
fi
echo ${Vless_UUID}

if [[ -z "${Vmess_Path}" ]]; then
  Vmess_Path="/s244"
fi
echo ${Vmess_Path}

if [[ -z "${Vmess_UUID}" ]]; then
  Vmess_UUID="5c301bb8-6c77-41a0-a606-4ba11bbab084"
fi
echo ${Vmess_UUID}

if [[ -z "${Share_Path}" ]]; then
  Share_Path="/share233"
fi
echo ${Share_Path}

rm -rf /etc/localtime
ln -sf /usr/share/zoneinfo/Europe/UnitedKingdom/etc/localtime
date -R

if [ "$VER" = "latest" ]; then
  XRAY_URL="https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-32.zip"
else
  VER="v$VER"
  XRAY_URL="https://github.com/XTLS/Xray-core/releases/download/${VER}/Xray-linux-32.zip"
fi

if [ "$VER" = "latest" ]; then
  XRAY_URL="https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip"
else
  VER="v$VER"
  XRAY_URL="https://github.com/XTLS/Xray-core/releases/download/${VER}/Xray-linux-64.zip"
fi

VER="latest"
mkdir /Xraybin
cd /Xraybin
echo ${XRAY_URL}
wget --no-check-certificate -qO 'Xray.zip' ${XRAY_URL}
unzip Xray.zip
rm -rf Xray.zip
chmod +x Xray
