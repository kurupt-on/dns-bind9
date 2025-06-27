#!/bin/bash

test_user() {
	if [ "$USERID" -ne "0" ]; then
		echo "Execute como root (sudo)" 
		exit 1
	fi
}

update_install_bind() {
	echo "Atualizando pacotes e baixando o bind9 mais recente."
	echo "nameserver 8.8.8.8" > /etc/resolv.conf
	apt update &>/dev/null
	apt install bind9 bind9-dnsutils -y  &>/dev/null
	echo "nameserver 127.0.0.1" > /etc/resolv.conf
	clear
}

choice_0() {
	
	use_init_view
	clear
	read -p "Nome do Dominio: " DOMAIN
	read -p "IP do domínio: " IPDOMAIN
	read -p "Configurar reverso?	[y p/ sim] " REVERSE_CFG
	read -p "Configurar slave? 	[y p/ sim] " SLAVE_CFG

	if [ "$SLAVE_CFG" = "y" ]; then
		read -p "IP do servidor slave: " IP_SLAVE
		ALLOW_TRANSFER="$IP_SLAVE"
		IXFR="yes"
	fi

	if [ "$REVERSE_CFG" = "y" ]; then
		REVERSE=$(echo "$IPDOMAIN" | awk -F'.' '{print $3 "." $2 "." $1}')
		REVERSE_VARIATION=$(echo "$IPDOMAIN" | awk -F'.' '{print $4}')

		cat >> /etc/bind/named.conf.local << EOF
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
	sleep 1
	USE_ACL=""
	if [ $ACL_ON -eq 1 -a $VIEW_ON -eq 0 ]; then 
		if [ "$USE_ACL" = "y" ]; then
			use_acl
		fi
	fi
	> /etc/bind/named.conf.options

	cat >> /etc/bind/named.conf.local << EOF
zone "$DOMAIN" {
	type master;
	file "db.$DOMAIN";
	allow-transfer { $ALLOW_TRANSFER; };
};
EOF

	cat >> /etc/bind/named.conf.options << EOF
options {
	directory "/var/cache/bind";
	listen-on-v6 { none; };
	dnssec-validation auto;
	recursion no;
	allow-recursion { none; };
	provide-ixfr $IXFR;
};
EOF
	if [ "$VIEW_ON" -ne 1 ]; then
			cat >> /etc/bind/named.conf.options << EOF
listen-on { $LISTEN_ON; };
allow-query { $ALLOW_QUERY; };
EOF
	fi
		
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
	rm -f config.swp 
use_end_view
check_cfg
}

choice_1() {
	clear
	[ $ACL_ON -eq 0 ] || read -p "ACLs detectadas. Usar? [y p/ sim] " USE_ACL
	if [ "$USE_ACL" = "y" ]; then
		use_acl
	else
		> /etc/bind/named.conf.options
	fi

		cat >> /etc/bind/named.conf.options << EOF
options {
	directory "/var/cache/bind";
	listen-on { $LISTEN_ON; };
	allow-query { $ALLOW_QUERY; };
	listen-on-v6 { none; };
	recursion yes;
	dnssec-validation auto;
	allow-recursion { $ALLOW_RECURSION; };
EOF
	read -p "Configurar encaminhamento? 		[y p/ sim] " FWD_IN_CACHE
	if [ "$FWD_IN_CACHE" = "y" ]; then
		read -p "Configurar para um dominio interno?	[y p/ sim] " FWD_INT_IN_CACHE
		if [ "$FWD_INT_IN_CACHE" != "y" ]; then
			read -p "IP para encaminhamento: " IPDOMAIN
			cat >> /etc/bind/named.conf.options << EOF
	forwarders { $IPDOMAIN; };
EOF
		else
			read -p "Nome da Dominio: " DOMAIN
			read -p "IP do Dominio: " IPDOMAIN
			read -p "O dominio possui DNSSEC? 		[y p/ sim] " DNSSEC_IN_CACHE
			if [ "$DNSSEC_IN_CACHE" != "y" ]; then
				echo "	validate-except { \"$DOMAIN\"; };" >> /etc/bind/named.conf.options
			fi
			cat >> /etc/bind/named.conf.local << EOF
zone "$DOMAIN" {
	type forward;
	forwarders { $IPDOMAIN; };
};
EOF
		fi
	fi
	echo "};" >> /etc/bind/named.conf.options
	echo
	echo "Configuração de cache finalizada."
	sleep 1
}

choice_2() {
	clear
	read -p "IP para encaminhamento 1: " FORWARDER_1IP
	read -p "IP para encaminhamento 2: " FORWARDER_2IP
	echo
	cat >> /etc/bind/named.conf.options << EOF
options {
	directory "/var/cache/bind";
	forwarders { $FORWARDER_1IP; $FORWARDER_2IP; };
	forward only;
EOF
	[ $ACL_ON -eq 0 ] || read -p "ACLs detectadas. Usar?	[y p/ sim] " USE_ACL
	if [ "$USE_ACL" = "y" ]; then
		use_acl
		cat >> /etc/bind/named.conf.options << EOF
	allow-query { $ALLOW_QUERY; };
};
EOF
	else
		echo "};" >> /etc/bind/named.conf.options
		clean_extra
	fi
		echo
	echo "Configuração de encaminhamento finalizada."
	sleep 1
}

check_swp() {
	[ -e config.swp ] || touch "config.swp"
	grep "Default" config.swp
	ACL_DEFAULT_ON=$( echo $? )
	clear
	[ $ACL_DEFAULT_ON -eq 0 ] || read -p "Deseja adcionar a ACL \"Default\"  ->  localhost only. [y p/ sim] " ACL_DEFAULT
	[ $ACL_DEFAULT = "y" ] && cat >> config.swp << EOF
acl "Default" {
	localhost;
};

EOF
	ACL_DEFAULT=""
}

use_acl() {
	clear
	echo "As seguintes ACLs estão configuradas:"
	get_acl 
	echo
	echo "Associe os parametros com os números respectivos das ACLs."
	echo

	if [ $CHOICE -ne 2 ]; then
		read -p "listen-on: " LISTEN_ON
		read -p "allow-query: " ALLOW_QUERY
		if [ $VIEW_ON -eq 1 ]; then
			read -p "match-clients: " MATCH_CLIENTS 
			[ $MATCH_CLIENTS -eq $VAR ] && MATCH_CLIENTS=$( echo $GET_ACL | cut -d " " -f $VAR) || MATCH_CLIENTS=$( echo $GET_ACL | cut -d " " -f $MATCH_CLIENTS )
		fi
		[ $LISTEN_ON -eq $VAR ] && LISTEN_ON=$( echo $GET_ACL | cut -d " " -f $VAR) || LISTEN_ON=$( echo $GET_ACL | cut -d " " -f $LISTEN_ON )
		[ $ALLOW_QUERY -eq $VAR ] && ALLOW_QUERY=$( echo $GET_ACL | cut -d " " -f $VAR) || ALLOW_QUERY=$( echo $GET_ACL | cut -d " " -f $ALLOW_QUERY )

		if [ $CHOICE -eq 1 ]; then
			read -p "allow-recursion: " ALLOW_RECURSION
			[ $ALLOW_RECURSION -eq $VAR ] && ALLOW_RECURSION=$( echo $GET_ACL | cut -d " " -f $VAR) || ALLOW_RECURSION=$( echo $GET_ACL | cut -d " " -f $ALLOW_RECURSION )
		fi
	else
		read -p "allow-query: " ALLOW_QUERY
		[ $ALLOW_QUERY -eq $VAR ] && ALLOW_QUERY=$( echo $GET_ACL | cut -d " " -f $VAR) || ALLOW_QUERY=$( echo $GET_ACL | cut -d " " -f $ALLOW_QUERY )
	fi
	clean_extra
}

use_init_view() {
	if [ $VIEW_ON -eq 1 ]; then
		clear
		echo "Configurado para utilizar VIEWs."
		echo
		read -p "Nome da VIEW: " VIEW_NAME
		[ $ACL_ON -eq 0 ] || read -p "ACLs detectadas. Usar? [y p/ sim]" USE_ACL
		if [ "$USE_ACL" = "y" ]; then
			use_acl
		fi
		
		cat > '/etc/bind/named.conf.local' << EOF
view "$VIEW_NAME" {
	match-clients { "$MATCH_CLIENTS"; };
	listen-on { "$LISTEN_ON"; };
	allow-query { "$ALLOW_QUERY"; };
EOF
	fi
}

use_end_view() {
	[ $VIEW_ON -eq 1 ] && echo "};" >> /etc/bind/named.conf.local
}

get_acl() {
	GET_ACL=$(grep "acl" /etc/bind/named.conf.options | cut -d "\"" -f 2 | tr '\n' ' ')
	VAR=1
	for I in $GET_ACL; do
		printf "[$VAR] $I"
		[ "$I" = "Default" ] && printf "  ->  localhost only"
		printf "\n"
		VAR=$(( $VAR + 1 ))
	done

}

get_cfg_swp() {
	CHOICE_3=""
	clear
	echo "Modificações feitas:"
	echo
	[ -s config.swp ] && cat config.swp || echo "Sem ACLs configuradas." 
	printf "Status de VIEW: "
	[ "$VIEW" = "Habilitar" ] && echo "Desabilitado" || echo "Habilitado"
	echo
	while [ "$CHOICE_3" != "q" ]; do
		read -p "Pressione [q] para sair: " CHOICE_3
		sleep 1
	done
}

set_acl() {
	check_swp
	clear
	read -p "Nome da ACL: " ACL_NAME
	echo "acl \"$ACL_NAME\" {" >> config.swp 
	echo "Utilize Ctrl+D ao terminar de digitar."
	echo "Declare quem fará parte da sua ACL. (utilizar \";\" ao final da linha)"
	while read; do
		echo "	$REPLY" >> config.swp
	done
	echo "};" >> config.swp
	echo "" >> config.swp

}

set_view() {
	[ "$VIEW" = "Habilitar" ] && VIEW="Desabilitar" || VIEW="Habilitar"
}

set_cfg_swp() {
	[ -s config.swp ] && cat config.swp > /etc/bind/named.conf.options && ACL_ON="1"
	[ "$VIEW" = "Habilitar" ]  && VIEW_ON="0" || VIEW_ON="1"
	echo "Saindo do modo extra e salvando as configurações."
	sleep 1
}

choice_E() {
	clear
	while true; do
		clear
		echo "Configurações Extras."
		echo
		[ -s config.swp -o "$VIEW" = "Desabilitar" ] && STAT_CFG="* Configurações detectadas." || STAT_CFG="Sem configurações no momento."
		echo "$STAT_CFG" 
		echo
		echo "[M] - Mostrar Modificações"
		echo "[A] - Adionar Acl"
		echo "[V] - $VIEW View"
		echo "[W] - Sair e Salvar"
		echo "[S] - Sair sem Salvar"
		echo
		read -p "Opção: " EXTRA_CHOICE

		case "$EXTRA_CHOICE" in
			M) 
				get_cfg_swp
				;;
			A)
				set_acl
				;;
			V)
				set_view
				;;
			S)
				echo "Saindo do modo extra sem salvar."
				clean_extra
				sleep 1
				break
				;;
			W)
				set_cfg_swp
				break
				;;
			*)
				echo "Opção inválida."
				sleep 1
				choice_E
		esac
	done;	
		TERM_EXTRA="false"
		clear
}

menu_select() {
	clear
	while true; do
		echo "Iniciando a configuração do DNS."
		echo
		echo "0) Autoritativo"
		echo "1) Cache"
		echo "2) Encaminhamento"	
		echo
		echo "[E] - Configurações extras"
		echo "[S] - Sair"
		echo 
		read -p "Opção: " CHOICE
		case "$CHOICE" in
			0)
				choice_0
				break
				;;
			1)
				choice_1
				break
				;;
			2)
				choice_2
				break
				;;
			E)
				choice_E
				;;
			S)
				echo "Finalizando o script."
				sleep 1
				echo
				exit 0
				;;
			*)
				echo "Opção inválida."
				sleep 1
		esac
	done
}

clean-bind() {
	echo "Limpando o ambiente."
	rm -rf /var/cache/bind &>/dev/null
	apt remove --purge bind9 -y &>/dev/null
}

clean_extra() {
	rm -f config.swp &>/dev/null
}

restart_bind() {
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

check_pre_extant() {
	if [ -d /etc/bind/ -o -d /var/cache/bind/ ];then
		clear
		echo "Verificado arquivos pré-existentes." 
		sleep 1
		clean-bind
	fi
}

check_net() {
	ping -c 1 8.8.8.8 &>/dev/null
	[ $? -ne 0 ] && echo "Erro de conexão" && exit 1
}
