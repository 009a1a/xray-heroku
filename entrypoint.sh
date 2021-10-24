#! /bin/bash
set -ex
if [[ -z "${VER}" ]]; then
  VER="latest"
fi
echo ${VER}

if [[ -z "${vmess_UUID}" ]]; then
  UUID="86d9b8a7-9dfa-42f4-b9ac-f6b9a9beacda"
fi
echo ${vmess_UUID}

if [[ -z "${vmess_AlterID}" ]]; then
  AlterID="64"
fi
echo ${vmess_AlterID}

if [[ -z "${vmess_Path}" ]]; then
  vmess_Path="/static"
fi
echo ${vmess_Path}

if [[ -z "${vmess_QR_Path}" ]]; then
  vmess_QR_Path="qr_img"
fi
echo ${vmess_QR_Path}

if [[ -z "${Vless_UUID}" ]]; then
  Vless_UUID="5c301bb8-6c77-41a0-a606-4ba11bbab084"
fi
echo ${Vless_UUID}

if [[ -z "${Vless_Path}" ]]; then
  Vless_Path="/static"
fi
echo ${Vless_Path}

if [[ -z "${vless_QR_Path}" ]]; then
  vless_QR_Path="qr_img"
fi
echo ${vless_QR_Path}

rm -rf /etc/localtime
ln -sf /usr/share/zoneinfo/Europe/UnitedKingdom/etc/localtime
date -R

if [ "$VER" = "latest" ]; then
  XRAY_URL="https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-32.zip"
else
  X_VER="v$VER"
  XRAY_URL="https://github.com/XTLS/Xray-core/releases/download/$V_VER/Xray-linux-32.zip"
fi

if [ "$VER" = "latest" ]; then
  XRAY_URL="https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip"
else
  X_VER="v$VER"
  XRAY_URL="https://github.com/XTLS/Xray-core/releases/download/$V_VER/Xray-linux-64.zip"
fi

X_VER="latest"
mkdir /Xraybin
cd /Xraybin
echo ${XRAY_URL}
wget --no-check-certificate -qO 'Xray.zip' ${XRAY_URL}
unzip Xray.zip
rm -rf Xray.zip
chmod +x Xray

N_VER="v1.20.1"
mkdir /nginxbin
cd /nginxbin
CADDY_URL="https://nginx.org/download/nginx-1.20.1.tar.gz"
echo ${NGINX_URL}
wget --no-check-certificate -qO 'nginx.tar.gz' ${NGINX_URL}
tar xvf nginx.tar.gz
rm -rf nginx.tar.gz
chmod +x nginx

cd /wwwroot
tar xvf wwwroot.tar.gz
rm -rf wwwroot.tar.gz

cat <<-EOF > /etc/Xraybin/config.json
{
    "log":{
        "loglevel":"warning"
    },
"inbounds": [
        {
            "listen": "0.0.0.0",
            "port": 12346,
            "protocol": "vless",
            "settings": {
                "clients": [
                    {
                        "id": "${Vless_UUID}"
                    }
                ],
                "decryption": "none"
            },
            "streamSettings": {
                "network": "ws",
                "security": "none",
                "wsSettings": {
                    "acceptProxyProtocol": false,
                    "path": "${Vless_Path}"
                }
            }
        },
        {
            "listen": "0.0.0.0",
            "port": 12346,
            "protocol": "vmess",
            "settings": {
                "clients": [
                    {
                    "id": "${Vmess_UUID}",
                    "level": 0,
                    "alterId": 0,
                    "email": "love@xray.com"
                    }
                ],
                "disableInsecureEncryption": false
            },
            "streamSettings": {
                "network": "ws",
                "security": "none",
                "wsSettings": {
                    "acceptProxyProtocol": false,
                    "path": "${Vmess_Path}"
                }
            }
        }
    ],
    "outbounds": [
        {
            "protocol": "freedom",
            "tag": "direct"
        },
        {
            "protocol": "blackhole",
            "tag": "block"
        }
    ]
}
EOF                          

echo /etc/Xraybin/config.json
cat /etc/Xraybin/config.json

cat <<-EOF > /caddybin/Caddyfile
http://0.0.0.0:${PORT}
{
	root /wwwroot
	index index.html
	timeouts none
	proxy ${X_Path} localhost:12346 {
		websocket
		header_upstream -Origin
	}
}
EOF

cat <<-EOF > /etc/Xraybin/vmess.json
{
    "x": "ray",
    "ps": "${AppName}.herokuapp.com",
    "add": "${AppName}.herokuapp.com",
    "port": "443",
    "id": "${UUID}",
    "aid": "${AlterID}",
    "net": "ws",
    "type": "none",
    "host": "",
    "path": "${Vmess_Path}",
    "tls": "tls"
}
EOF

cat <<-EOF > /etc/Xraybin/vless.json
{
    "x": "ray",
    "ps": "${AppName}.herokuapp.com",
    "add": "${AppName}.herokuapp.com",
    "port": "443",
    "id": "${UUID}",
    "decryption": "none"
    "net": "ws",
    "type": "none",
    "host": "",
    "path": "${Vless_Path}",
    "tls": "tls"
}
EOF

if [ "$AppName" = "no" ]; then
  echo "Do not generate QR code"
else
  mkdir /wwwroot/${vmess_QR_Path}
  vmess="vmess://$(cat /xraybin/vmess.json | base64 -w 0)"
  Linkbase64=$(echo -n "${vmess}" | tr -d '\n' | base64 -w 0)
  echo "${Linkbase64}" | tr -d '\n' > /wwwroot/${vmess_QR_Path}/index.html
  echo -n "${vmess}" | qrencode -s 6 -o /wwwroot/${vmess_QR_Path}/vmess.png
else
  mkdir /wwwroot/${vless_QR_Path}
  vless="vless://$(cat /etc/xraybin/vless.json | base64 -w 0)"
  Linkbase64=$(echo -n "${vless}" | tr -d '\n' | base64 -w 0)
  echo "${Linkbase64}" | tr -d '\n' > /wwwroot/${vless_QR_Path}/index.html
  echo -n "${vless}" | qrencode -s 6 -o /wwwroot/${vless_QR_Path}/vless.png
fi

cd /Xraybin
./Xray -config config.json &
cd /caddybin
./caddy -conf="Caddyfile"
