#! / bin / sh
#
# rc.DMZ.firewall - Script do DMZ IP Firewall para Linux 2.4.xe iptables
#
# Copyright (C) 2001 Oskar Andreasson <bluefluxATkoffeinDOTnet>
#
# Este programa é um software livre; você pode redistribuí-lo e / ou modificar
# nos termos da Licença Pública Geral GNU, publicada por
# a Free Software Foundation; versão 2 da licença.
#
# Este programa é distribuído na esperança de que seja útil,
# mas SEM QUALQUER GARANTIA; sem sequer a garantia implícita de
# COMERCIABILIDADE ou ADEQUAÇÃO A UM OBJETIVO ESPECÍFICO. Veja o
# GNU General Public License para mais detalhes.
#
# Você deveria ter recebido uma cópia da Licença Pública Geral GNU
# junto com este programa ou no site em que você o baixou
# de; caso contrário, escreva para a Free Software Foundation, Inc., 59 Temple.
# Place, Suite 330, Boston, MA 02111-1307 EUA
#

########################################################### #########################
#
# 1. Opções de configuração.
#

#
# 1.1 Configuração da Internet.
#

INET_IP = "194.236.50.152"
HTTP_IP = "194.236.50.153"
DNS_IP = "194.236.50.154"
INET_IFACE = "eth0"

#
# 1.1.1 DHCP
#

#
# 1.1.2 PPPoE
#

#
# 1.2 Configuração da rede local.
#
# faixa de IP da sua LAN e IP do host local. / 24 significa usar apenas os primeiros 24
# bits do endereço IP de 32 bits. o mesmo que máscara de rede 255.255.255.0
#

LAN_IP = "192.168.0.1"
LAN_IFACE = "eth1"

#
Configuração DMZ # 1.3.
#

DMZ_HTTP_IP = "192.168.1.2"
DMZ_DNS_IP = "192.168.1.3"
DMZ_IP = "192.168.1.1"
DMZ_IFACE = "eth2"

#
# 1.4 Configuração do host local.
#

LO_IFACE = "lo"
LO_IP = "127.0.0.1"

#
# 1.5 Configuração de IPTables.
#

IPTABLES = "/ usr / sbin / iptables"

#
# 1.6 Outra configuração.
#

########################################################### #########################
#
# 2. Carregamento do módulo.
#

#
# Necessário para carregar inicialmente os módulos
#
/ sbin / depmod -a



#
# 2.1 Módulos necessários
#

/ sbin / modprobe ip_tables
/ sbin / modprobe ip_conntrack
/ sbin / modprobe iptable_filter
/ sbin / modprobe iptable_mangle
/ sbin / modprobe iptable_nat
/ sbin / modprobe ipt_LOG
/ sbin / modprobe ipt_limit
/ sbin / modprobe ipt_state

#
# 2.2 Módulos não necessários
#

# / sbin / modprobe ipt_owner
# / sbin / modprobe ipt_REJECT
# / sbin / modprobe ipt_MASQUERADE
# / sbin / modprobe ip_conntrack_ftp
# / sbin / modprobe ip_conntrack_irc
# / sbin / modprobe ip_nat_ftp
# / sbin / modprobe ip_nat_irc

########################################################### #########################
#
/ Proc configurado.
#

#
# 3.1 Configuração proc necessária
#

eco "1"> / proc / sys / net / ipv4 / ip_forward

#
# 3.2 Configuração de processo não necessária
#

#echo "1"> / proc / sys / net / ipv4 / conf / all / rp_filter
#echo "1"> / proc / sys / net / ipv4 / conf / all / proxy_arp
#echo "1"> / proc / sys / net / ipv4 / ip_dynaddr

########################################################### #########################
#
# 4. regras criadas.
#

######
# 4.1 Tabela de filtros
#

#
# 4.1.1 Definir políticas
#

$ IPTABLES -P INPUT DROP
$ IPTABLES -P DROP DE SAÍDA
$ IPTABLES -P FORWARD GOTA

#
# 4.1.2 Criar cadeias especificadas pelo usuário
#

#
# Criar cadeia para pacotes tcp incorretos
#

$ IPTABLES -N bad_tcp_packets

#
# Crie cadeias separadas para o ICMP, TCP e UDP atravessarem
#

$ IPTABLES -N permitido
$ IPTABLES -N icmp_packets

#
# 4.1.3 Criar conteúdo em cadeias especificadas pelo usuário
#

#
# bad_tcp_packets chain
#

$ IPTABLES -A bad_tcp_packets -p tcp --tcp-flags SYN, ACK SYN, ACK \
-m state --state NEW -j REJECT --reject-with tcp-reset
$ IPTABLES -A bad_tcp_packets -p tcp! --syn -m state --state NEW -j LOG \
--log-prefix "Novo não sincronizado:"
$ IPTABLES -A bad_tcp_packets -p tcp! --syn -m state --state NEW -j DROP

#
# cadeia permitida
#

$ IPTABLES -A permitido -p TCP --syn -j ACCEPT
$ IPTABLES -A permitido -p TCP -m state --state ESTABELECIDO, RELACIONADO -j ACEITO
$ IPTABLES -A permitido -p TCP -j DROP

#
# Regras de ICMP
#

# Regras totalmente alteradas
$ IPTABLES -A icmp_packets -p ICMP -s 0/0 --icmp-type 8 -j ACEITAR
$ IPTABLES -A icmp_packets -p ICMP -s 0/0 --icmp-type 11 -j ACEITAR

#
# 4.1.4 Cadeia de ENTRADA
#

#
# Pacotes TCP ruins que não queremos
#

$ IPTABLES -A INPUT -p tcp -j bad_tcp_packets

#
# Pacotes da Internet para esta caixa
#

$ IPTABLES -A INPUT -p ICMP -i $ INET_IFACE -j icmp_packets

#
# Pacotes da LAN, DMZ ou LOCALHOST
#

#
# Da interface DMZ ao IP do firewall DMZ
#

$ IPTABLES -A INPUT -p ALL -i $ DMZ_IFACE -d $ DMZ_IP -j ACEITAR

#
# Da interface da LAN ao IP do firewall da LAN
#

$ IPTABLES -A INPUT -p ALL -i $ LAN_IFACE -d $ LAN_IP -j ACEITAR

#
# Da interface do host local para os IP do host local
#

$ IPTABLES -A INPUT -p ALL -i $ LO_IFACE -s $ LO_IP -j ACEITAR
$ IPTABLES -A INPUT -p ALL -i $ LO_IFACE -s $ LAN_IP -j ACEITAR
$ IPTABLES -A INPUT -p ALL -i $ LO_IFACE -s $ INET_IP -j ACEITAR

#
# Regra especial para solicitações DHCP da LAN, que não são capturadas corretamente
# de outra forma.
#

$ IPTABLES -A INPUT -p UDP -i $ LAN_IFACE --dport 67 --sport 68 -j ACEITAR

#
# Todos os pacotes estabelecidos e relacionados que chegam da Internet para o
# firewall
#

$ IPTABLES -A INPUT -p ALL -d $ INET_IP -m state --state ESTABELECIDO, RELACIONADO \
-j ACEITA

#
# Nas redes Microsoft, você será inundado por transmissões. Estas linhas
# impedirá que eles apareçam nos logs.
#

# $ IPTABLES -A INPUT -p UDP -i $ INET_IFACE -d $ INET_BROADCAST \
# - porta de destino 135: 139 -j DROP

#
# Se recebermos solicitações DHCP de fora da nossa rede, nossos logs serão
# ser inundado também. Esta regra impedirá que eles sejam registrados.
#

# $ IPTABLES -A INPUT -p UDP -i $ INET_IFACE -d 255.255.255.255 \
# - porta de destino 67:68 -j DROP

#
# Se você tiver uma rede Microsoft na parte externa do seu firewall, poderá
# também são inundados por Multicasts. Nós os largamos para não sermos inundados por
# logs
#

# $ IPTABLES -A INPUT -i $ INET_IFACE -d 224.0.0.0/8 -j DROP

#
# Registre pacotes estranhos que não correspondem aos itens acima.
#

$ IPTABLES -A INPUT -m limit --limit 3 / minute --limit-burst 3 -j LOG \
--log DEBUG - prefixo de log "IPT INPUT packet morreu:"

#
# 4.1.5 Corrente FORWARD
#

#
# Pacotes TCP ruins que não queremos
#

$ IPTABLES -A FORWARD -p tcp -j bad_tcp_packets


#
Seção # DMZ
#
# Regras gerais
#

$ IPTABLES -A FORWARD -i $ DMZ_IFACE -o $ INET_IFACE -j ACEITAR
$ IPTABLES -A FORWARD -i $ INET_IFACE -o $ DMZ_IFACE -m state \
--status ESTABELECIDO, RELACIONADO -j ACEITA
$ IPTABLES -A FORWARD -i $ LAN_IFACE -o $ DMZ_IFACE -j ACEITAR
$ IPTABLES -A FORWARD -i $ DMZ_IFACE -o $ LAN_IFACE -m state \
--status ESTABELECIDO, RELACIONADO -j ACEITA

#
# Servidor HTTP
#

$ IPTABLES -A FORWARD -p TCP -i $ INET_IFACE -o $ DMZ_IFACE -d $ DMZ_HTTP_IP \
--port 80 -j permitido
$ IPTABLES -A FORWARD -p ICMP -i $ INET_IFACE -o $ DMZ_IFACE -d $ DMZ_HTTP_IP \
-j icmp_packets

#
# Servidor dns
#

$ IPTABLES -A FORWARD -p TCP -i $ INET_IFACE -o $ DMZ_IFACE -d $ DMZ_DNS_IP \
--port 53 -j permitido
$ IPTABLES -A FORWARD -p UDP -i $ INET_IFACE -o $ DMZ_IFACE -d $ DMZ_DNS_IP \
--dport 53 -j ACEITAR
$ IPTABLES -A FORWARD -p ICMP -i $ INET_IFACE -o $ DMZ_IFACE -d $ DMZ_DNS_IP \
-j icmp_packets

#
# Seção LAN
#

$ IPTABLES -A FORWARD -i $ LAN_IFACE -j ACEITA
$ IPTABLES -A FORWARD -m state --state ESTABELECIDO, RELACIONADO -j ACEITA

#
# Registre pacotes estranhos que não correspondem aos itens acima.
#

$ IPTABLES -A FORWARD -m limit --limit 3 / minute --limit-burst 3 -j LOG \
--log DEBUG-level - prefixo de log "IPT FORWARD packet morreu:"

#
# 4.1.6 Cadeia de saída
#

#
# Pacotes TCP ruins que não queremos.
#

$ IPTABLES -A OUTPUT -p tcp -j bad_tcp_packets

#
Regras de saída especiais para decidir quais IPs permitir.
#

$ IPTABLES -A OUTPUT -p ALL -s $ LO_IP -j ACEITAR
$ IPTABLES -A OUTPUT -p ALL -s $ LAN_IP -j ACEITAR
$ IPTABLES -A OUTPUT -p ALL -s $ INET_IP -j ACEITAR

#
# Registre pacotes estranhos que não correspondem aos itens acima.
#

$ IPTABLES -A OUTPUT -m limit --limit 3 / minute --limit-burst 3 -j LOG \
--log DEBUG - prefixo de log "IPT OUTPUT packet morreu:"

######
# 4.2 tabela nat
#

#
# 4.2.1 Definir políticas
#

#
# 4.2.2 Criar cadeias especificadas pelo usuário
#

#
# 4.2.3 Criar conteúdo em cadeias especificadas pelo usuário
#

#
# 4.2.4 Cadeia de PREROUTING
#

$ IPTABLES -t nat -A PREROUTING -p TCP -i $ INET_IFACE -d $ HTTP_IP --dport 80 \
-j DNAT --para $ DMZ_HTTP_IP de destino
$ IPTABLES -t nat -A PREROUTING -p TCP -i $ INET_IFACE -d $ DNS_IP - relatório 53 \
-j DNAT --para o destino $ DMZ_DNS_IP
$ IPTABLES -t nat -A PREROUTING -p UDP -i $ INET_IFACE -d $ DNS_IP - relatório 53 \
-j DNAT --para o destino $ DMZ_DNS_IP

#
# 4.2.5 Cadeia POSTROUTING
#

#
# Ativar encaminhamento de IP simples e conversão de endereços de rede
#

$ IPTABLES -t nat -A POSTROUTING -o $ INET_IFACE -j SNAT - para fonte $ INET_IP

#
# 4.2.6 Cadeia de SAÍDA
#

######
Mesa mangle # 4.3
#

#
# 4.3.1 Definir políticas
#

#
# 4.3.2 Criar cadeias especificadas pelo usuário
#

#
# 4.3.3 Criar conteúdo em cadeias especificadas pelo usuário
#

#
# 4.3.4 Cadeia de PREROUTING
#

#
# 4.3.5 Cadeia de ENTRADA
#

#
# 4.3.6 Corrente FORWARD
#

#
# 4.3.7 Cadeia de saída
#

#
# 4.3.8 Cadeia POSTROUTING
#

