#!/bin/bash

test-user() {
	if [ "$USERID" -ne "0" ]; then
		echo "Execute como root (sudo)"
		exit 1
	fi
}

update_install() {
	echo "nameserver 8.8.8.8" > /etc/resolv.conf
	apt update 
	apt install bind9 bind9-dnsutils -y 
	echo "nameserver 127.0.0.1" > /etc/resolv.conf
	clear
}

menu_select() {
	echo "escolha o tipo de servidor DNS."
	echo "0) Autoritativo"
	echo "1) Cache"
	echo "2) Encaminhamento"	
	echo 
	read -p "Opção padrão[0]: " CHOICE

	case "$CHOICE" in
		0)
			
			read -p "Dominio: " DOMAIN
			read -p "IP do domínio: " IPDOMAIN
			cat > /etc/bind/named.conf.local << EOF
zone "$DOMAIN" {
	type master;
	file "db.$DOMAIN";
	allow-transfer { none; };
};
EOF
			cat > /etc/bind/named.conf.options << EOF
options {
	directory "/var/cache/bind";
	listen-on-v6 { none; };
	dnssec-validation auto;
	recursion no;
	allow-recursion { none; };
};
EOF
		
			cat > /var/cache/bind/db.$DOMAIN << EOF
\$TTL 8h
\$ORIGIN $DOMAIN.

@	IN	SOA	ns1.$DOMAIN. adm.$DOMAIN. (
			$( date +%Y%m%d)01	;	SERIAL
			3600		;	REFRESH
			1800		;	RETRY
			604800		;	EXPIRE
			3600		;	NEGATIVE TTL
			);

@	IN	NS	ns1.$DOMAIN.
ns1	IN	A	$IPDOMAIN

EOF

			;;
		
		1)
			cat > /etc/bind/named.conf.options << EOF
options {
	directory "/var/cache/bind";
	listen-on { localhost; };
	allow-query { localhost; };
	listen-on-v6 { none; };
	recursion yes;
	allow-recursion { localhost; };

};

EOF
			;;
		2)
			read -p "IP para encaminhamento 1: " FORWARDER_1IP
			read -p "IP para encaminhamento 2: " FORWARDER_2IP
			cat > /etc/bind/named.conf.options << EOF
options {
	directory "/var/cache/bind";
	forwarders { $FORWARDER_1IP; $FORWARDER_2IP; };
	forward only;
};

EOF
			;;
		*)
			echo "Opção inválida."
			exit 1
	esac
}

clean-bind() {
	rm /var/cache/bind/*
	apt remove --purge bind9* -y

}

restart-bind() {
	systemctl restart named.service
	if [ $? -ne "0" ]; then
		echo "Erro na reinicialização do bind."
		exit 1
	fi

}



