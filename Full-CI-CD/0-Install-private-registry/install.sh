#!/bin/bash

: ' write refrences for more searching
    refrence: https://phoenixnap.com/kb/set-up-a-private-docker-registry
'

check_root_access() {
  if [ "$EUID" -ne 0 ]
    then echo -e "\033[31mRun this script on sudo permission ..."
    exit
  fi
}

create_registry_directories() {
  if [ -d "/root/registry" ] 
  then
    echo -e "\033[32mRegistry directories exists." 
  else
    echo "Creating registry paths"
    mkdir /root/registry
    mkdir /root/registry/nginx
    mkdir /root/registry/auth
    mkdir -p /root/registry/nginx/conf.d
    mkdir -p /root/registry/nginx/ssl
  fi

  cp ./registry.conf /root/registry/nginx/conf.d/
}

create_ssl_dir_and_file() {
  if [ -d "/root/create-ssl" ]
    then
      echo -e "\033[32ssl directories exists."
    else
      echo "Creating ssls files ..."
      mkdir /root/create-ssl 
      mkdir /root/create-ssl/keys
      mkdir /root/create-ssl/certs
    fi
    
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /root/create-ssl/keys/fullchain.key -out /root/create-ssl/certs/fullchain.crt

    openssl dhparam -out /root/create-ssl/certs/fullchain.pem 2048
    openssl dhparam -out /root/create-ssl/keys/privkey.pem 2048

    cp /root/create-ssl/certs/fullchain.pem /root/registry/nginx/ssl/
    cp /root/create-ssl/keys/privkey.pem /root/registry/nginx/ssl/
}

create_registry_passwrd() {
  echo "[+] Request a new password file named {registry.passwd} for your user"
  
  apt install apache2-utils -y

  htpasswd -Bc registry.passwd hacktor
  mv ./registry.passwd /root/registry/auth/registry.passwd

  if [ ! -d "./tmp" ]
    then
      mkdir ./tmp
      touch ./tmp/rootCA.crt
  fi

  if [ ! -d "/etc/docker/certs.d/registry.hacktor.com" ]
    then
      mkdir -p /etc/docker/certs.d/registry.hacktor.com
      mkdir -p /usr/share/ca-certificates/extra/
  fi

  openssl x509 -in rootCA.pem -inform PEM -out ./tmp/rootCA.crt

  mkdir -p /etc/docker/certs.d/registry.hacktor.com/
  mkdir -p /usr/share/ca-certificates/extra/
  cp ./tmp/rootCA.crt /etc/docker/certs.d/registry.hacktor.com/
  cp ./tmp/rootCA.crt /usr/share/ca-certificates/extra/
  rm -rf ./tmp

  dpkg-reconfigure ca-certificates
}

check_root_access
create_registry_directories
create_ssl_dir_and_file
create_registry_passwrd

systemctl restart docker

echo "[+] Start building image ..."

docker-compose up -d
