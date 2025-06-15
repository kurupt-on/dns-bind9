#!/bin/bash

USERID=$( id -u )
CHOICE="0"
DOMAIN=""
SLAVE=""
IPDOMAIN=""


if [ "$USERID" -ne "0" ]; then
	echo "Execute como root (sudo)"
	exit 1
fi

update_install() {
	apt update
	apt install bind9 bind9-dnsutils -y	
}

menu_select() {
	echo "escolha o tipo de servidor DNS."
	echo "0) Autoritativo"
	echo "1) Cache"
	echo "2) Recursivo"
	echo "3) Encaminhamento"	
	
	read -p "Opção padrão[0]: " CHOICE
	read -p "Dominio: " DOMAIN
	read -p "IP do domínio: " IPDOMAIN

	case "$CHOICE" in
		0)
			sed -i "23s/any/none/" /etc/bind/named.conf.options
			cat > /etc/bind/named.conf.local << EOF
zone "$DOMAIN" {
	type master;
	file "db.$DOMAIN";
	allow-transfer { none; };
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
;@	IN	MX	10 mail.$DOMAIN.

ns1	IN	A	$IPDOMAIN
;mail	IN	A	xxx.xxx.xxx.xxx	

EOF

			;;
		*)
			echo "Opção inválida."
	esac
}

#update_install
menu_select
