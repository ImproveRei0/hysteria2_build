#!/bin/bash
echo -e "\033[31m ************************** \033[0m"
echo -e "\033[31m 歇斯底里协议一键搭建脚本 \033[0m"
echo "  by rei"
echo "  Debian 8+ 适用"
echo -e "\033[31m ************************** \033[0m"
echo -e "\033[31m 确认执行脚本？,输入yes继续 \033[0m"
read confirm
if [ "$confirm" != "yes" ]
then
    echo "取消执行"
    exit
fi

apt-get update -y              
apt-get install curl sudo -y

bash <(curl -fsSL https://get.hy2.sh/)

openssl req -x509 -nodes -newkey ec:<(openssl ecparam -name prime256v1) -keyout /etc/hysteria/server.key -out /etc/hysteria/server.crt -subj "/CN=bing.com" -days 36500 && sudo chown hysteria /etc/hysteria/server.key && sudo chown hysteria /etc/hysteria/server.crt

echo "请输入您想要的端口："
read port

echo "是否自定义密码（1/0）："
read userpwd

password="K33cQAXsTHwevdcToT5XN9+Fzll+"

if [ "$userpwd" = "1" ]
then
	echo "请输入自定义密码："
	read password
fi

echo "通讯端口：$port"
echo "密码：$password"


echo "listen: :$port


tls:
  cert: /etc/hysteria/server.crt
  key: /etc/hysteria/server.key

auth:
  type: password
  password: $password   

masquerade:
  type: proxy
  proxy:
    url: https://bing.com 
    rewriteHost: true
" > /etc/hysteria/config.yaml

systemctl start hysteria-server.service

clear

echo ""
echo ""
echo ""

echo -e "\033[31m 脚本执行完毕！即将展示运行状态 \033[0m"

echo -e "\033[31m 配置状态: \033[0m"
echo "通讯端口：$port"
echo "密码：$password"
sleep 1

systemctl status hysteria-server.service

