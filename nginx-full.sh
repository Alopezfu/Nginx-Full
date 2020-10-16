#!/bin/bash

function print_help(){

    echo "Help nginx-full:"
    echo "\/Remember to run the script as administrator\/"
    echo -e "Command use: sudo ./nginx-full.sh \e[4mexample.com\e[0m \e[4myour@email.com\e[0m \e[4mnew_mysql_user\e[0m \e[4mnew_mysql_password\e[0m"
    echo -e " 1.\e[4mexample.com\e[0m: Domain value"
    echo -e " 2.\e[4myour@email.com\e[0m: Email value"
    echo -e " 3.\e[4mnew_mysql_user\e[0m: New User into Mysql value"
    echo -e " 4.\e[4mnew_mysql_password\e[0m: Password for the new user value"
}

function install(){

    clear
    echo "Installing certbot python3-certbot-nginx mysql-server php-fpm php-mysql."
    sleep 2
    apt update
    apt install -y certbot python3-certbot-nginx mysql-server php-fpm php-mysql
}

function setup_site(){

    clear
    fpm=$(ls /run/php/*.*.sock | cut -d '/' -f4)
    echo "Setup Nginx site for $domain."
    sleep 2
    rm /etc/nginx/sites-enabled/default
    touch /etc/nginx/sites-available/$domain
    mkdir /var/www/$domain
    echo 'server {
    listen 80;

    root /var/www/'$domain';
    index index.php index.html index.htm index.nginx-debian.html;

    server_name '$domain';

    location / {
            try_files $uri $uri/ =404;
    }

    location ~ \.php$ {
    include snippets/fastcgi-php.conf;
    fastcgi_pass unix:/run/php/'$fpm';
    }

    location ~ /\.ht { 
        deny all;
    }

}
    ' >> /etc/nginx/sites-available/$domain
    ln -s /etc/nginx/sites-available/$domain /etc/nginx/sites-enabled/
    systemctl reload nginx.service
}

function setup_ufw(){

    clear
    echo "Setup UFW (Nginx Full Ssh)"
    sleep 2
    ufw allow 'Nginx Full'
    ufw delete allow 'Nginx HTTP'
    ufw allow 'ssh'
    ufw --force enable
}

function get_ssl(){

    certbot --nginx --non-interactive --agree-tos --email $email  -d $domain
}

function setup_php(){

    sed -i 's/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g' /etc/php/$(ls /etc/php/)/fpm/php.ini
    systemctl restart php$(ls /etc/php/)-fpm
}

function mysql_user(){

    clear
    echo "Setup Mysql user ($mysql_user)"
    sleep 2
    mysql -e "CREATE USER '$mysql_user'@'localhost' IDENTIFIED BY '$mysql_password'"
    mysql -e "GRANT ALL PRIVILEGES ON *.* TO '$mysql_user'@'localhost';"
    echo "Mysql login:"
    echo "\t User: $mysql_user"
    echo "\t Password: $mysql_password"

}

function main(){

    domain=$1
    email=$2
    mysql_user=$3
    mysql_password=$4
    if [[ ! -z $domain ]] && [[ ! -z $email ]] && [[ ! -z $mysql_password ]] && [[ ! -z $mysql_user ]] && [[ $UID -eq 0 ]] ;
    then
        install
        setup_ufw
        setup_php
        setup_site
        mysql_user 
        # get_ssl
    else
        print_help
    fi
}

main $1 $2 $3 $4
