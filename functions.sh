#!/bin/bash

test_user() {
	if [ "$USERID" -ne "0" ]; then
		echo "Execute como root (sudo)" 
		exit 1
	fi
}

update_install_bind() {
	echo "Atualizando pacotes e baixando o bind9."
	echo "nameserver 8.8.8.8" > /etc/resolv.conf
	apt update &>/dev/null
	apt install bind9 bind9-dnsutils -y  &>/dev/null
	echo "nameserver 127.0.0.1" > /etc/resolv.conf
	clear
}

choice_0() {
	read -p "Nome do Dominio: " DOMAIN
	read -p "IP do domínio: " IPDOMAIN
	read -p "Configurar reverso? [y|n] " REVERSE_CFG
	read -p "Configurar slave? [y|n] " SLAVE_CFG

	if [ "$SLAVE_CFG" = "y" ]; then
		read -p "IP do servidor slave: " IP_SLAVE
		ALLOW_TRANSFER="$IP_SLAVE"
		IXFR="yes"
	fi

	if [ "$REVERSE_CFG" = "y" ]; then
		REVERSE=$(echo "$IPDOMAIN" | awk -F'.' '{print $3 "." $2 "." $1}')
		REVERSE_VARIATION=$(echo "$IPDOMAIN" | awk -F'.' '{print $4}')

		cat > /etc/bind/named.conf.local << EOF
zone "$REVERSE.in-addr.arpa" {
	type master;
	file "db.$DOMAIN.rev";
	allow-transfer { $ALLOW_TRANSFER; };

};
EOF

		cat > /var/cache/bind/db.$DOMAIN.rev << EOF
\$TTL 8h

@	IN	SOA	ns1.$DOMAIN. adm.$DOMAIN. (
			$( date +%Y%m%d)01	;	SERIAL
			3600		;	REFRESH
			1800		;	RETRY
			604800		;	EXPIRE
			3600		;	NEGATIVE TTL
			);

@	IN	NS	ns1.$DOMAIN.
ns1	IN	A	$IPDOMAIN
$REVERSE_VARIATION	IN	PTR	ns1.$DOMAIN.

EOF

	fi

	cat >> /etc/bind/named.conf.local << EOF
zone "$DOMAIN" {
	type master;
	file "db.$DOMAIN";
	allow-transfer { $ALLOW_TRANSFER; };
};
EOF

	cat > /etc/bind/named.conf.options << EOF
options {
	directory "/var/cache/bind";
	listen-on { localhost; };
	allow-query { localhost; };
	listen-on-v6 { none; };
	dnssec-validation auto;
	recursion no;
	allow-recursion { none; };
	provide-ixfr $IXFR;
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
	echo	
	echo "Configuração autoritativa completa."
	sleep 1	

check_cfg
}

choice_1() {
	cat > /etc/bind/named.conf.options << EOF
options {
	directory "/var/cache/bind";
	listen-on { localhost; };
	allow-query { localhost; };
	listen-on-v6 { none; };
	recursion yes;
	dnssec-validation auto;
	allow-recursion { localhost; };
};

EOF
	echo
	echo "Configuração de cache finalizada."
	sleep 1
}

choice_2() {
	echo
	read -p "IP para encaminhamento 1: " FORWARDER_1IP
	read -p "IP para encaminhamento 2: " FORWARDER_2IP
	cat > /etc/bind/named.conf.options << EOF
options {
	directory "/var/cache/bind";
	forwarders { $FORWARDER_1IP; $FORWARDER_2IP; };
	forward only;
};

EOF
	echo
	echo "Configuração de encaminhamento finalizada."
	sleep 1
}

menu_select() {
	echo "escolha o tipo de servidor DNS."
	echo
	echo "0) Autoritativo"
	echo "1) Cache"
	echo "2) Encaminhamento"	
	echo 
	read -p "Opção: " CHOICE

	case "$CHOICE" in
		0)
			choice_0
			;;
		1)
			choice_1
			;;
		2)
			choice_2
			;;
		*)
			echo "Opção inválida."
			exit 1
	esac
}

clean-bind() {
	echo "Preparando o ambiente."
	rm -f /var/cache/bind/* &>/dev/null
	apt remove --purge bind9* -y &>/dev/null
}

restart-bind() {
	echo "Reiniciando o serviço."
	systemctl restart named.service
	sleep 1
	echo 
	if [ $? -ne 0 ]; then
        echo "Erro na reinicialização do BIND9. Veja 'journalctl -u named.service'."
        exit 1
	fi
	if [ "$CHOICE" = "0" ]; then
		echo "Teste com: dig @localhost ns1.$DOMAIN"
		if [ "$REVERSE_CFG" = "y" ]; then
			echo "Teste zona reversa com: dig -x $IPDOMAIN"
		fi
	else
		echo "Teste com: dig @localhost google.com"
	fi
}

check_cfg() {
	named-checkconf
	if [ $? -ne "0" ]; then
		echo "Erro de configuração do bind."
		exit 1
	fi
}

