#!/bin/bash
echo -e "\033[31m ************************** \033[0m"
echo -e "\033[31m Hysteria protocol one-click setup script \033[0m"
echo -e "\033[31m *English Mode* \033[0m"
echo "  by rei"
echo "  Suitable for Debian 8+"
echo -e "\033[31m ************************** \033[0m"
echo -e "\033[31m Confirm to execute the script? Input yes to continue \033[0m"
read confirm
if [ "$confirm" != "yes" ]
then
    echo "Execution cancelled"
    exit
fi

apt-get update -y              
apt-get install curl sudo -y

bash <(curl -fsSL https://get.hy2.sh/)

openssl req -x509 -nodes -newkey ec:<(openssl ecparam -name prime256v1) -keyout /etc/hysteria/server.key -out /etc/hysteria/server.crt -subj "/CN=bing.com" -days 36500 && sudo chown hysteria /etc/hysteria/server.key && sudo chown hysteria /etc/hysteria/server.crt

echo "Please enter the port you want:"
read port

echo "Customize the password? (1/0):"
read userpwd

password="K33cQAXsTHwevdcToT5XN9+Fzll+"

if [ "$userpwd" = "1" ]
then
 echo "Enter custom password:"
 read password
fi

echo "Communication port: $port"
echo "Password: $password"


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

echo -e "\033[31m The script has been executed! Now displaying the running status \033[0m"

echo -e "\033[31m Configuration status: \033[0m"
echo "Communication port: $port"
echo "Password: $password"
sleep 1

systemctl status hysteria-server.service
