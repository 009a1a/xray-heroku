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

cd /wwwroot
tar xvf wwwroot.tar.gz
rm -rf wwwroot.tar.gz

sed -e "/^#/d"\
    -e "s/\${Vless_UUID}/${Vless_UUID}/g"\
    -e "s|\${Vless_Path}|${Vless_Path}|g"\
    -e "s/\${Vmess_UUID}/${Vmess_UUID}/g"\
    -e "s|\${Vmess_Path}|${Vmess_Path}|g"\
    /conf/Xray.template.json >  /xraybin/config.json
echo /xraybin/config.json
cat /xraybin/config.json

if [[ -z "${ProxySite}" ]]; then
  s="s/proxy_pass/#proxy_pass/g"
  echo "site:use local wwwroot html"
else
  s="s|\${ProxySite}|${ProxySite}|g"
  echo "site: ${ProxySite}"
fi

sed -e "/^#/d"\
    -e "s/\${PORT}/${PORT}/g"\
    -e "s|\${Vless_Path}|${Vless_Path}|g"\
    -e "s|\${Vmess_Path}|${Vmess_Path}|g"\
    -e "s|\${Share_Path}|${Share_Path}|g"\
    -e "$s"\
    /conf/nginx.template.conf > /etc/nginx/conf.d/ray.conf
echo /etc/nginx/conf.d/ray.conf
cat /etc/nginx/conf.d/ray.conf

[ ! -d /wwwroot/${Share_Path} ] && mkdir -p /wwwroot/${Share_Path}
sed -e "/^#/d"\
    -e "s|\${_Vless_Path}|${Vless_Path}|g"\
    -e "s|\${_Vmess_Path}|${Vmess_Path}|g"\
    -e "s/\${_Vless_UUID}/${Vless_UUID}/g"\
    -e "s/\${_Vmess_UUID}/${Vmess_UUID}/g"\
    -e "$s"\
    /conf/share.html > /wwwroot/${Share_Path}/index.html
echo /wwwroot/${Share_Path}/index.html
cat /wwwroot/${Share_Path}/index.html

cd /xraybin
./xray run -c ./config.json &
rm -rf /etc/nginx/sites-enabled/default
nginx -g 'daemon off;'
