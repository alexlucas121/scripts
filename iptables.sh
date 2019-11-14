#!/bin/bash

###############################################################################
#                                                                             #
#                               IPTABLES.SH                                   #
#                Script de inicialização de regras de firewall                #
#                                                                             #
#                  Autor: José Guilherme Camara Ribeiro                       #
#                         <jgcr@pop.com.br>                                   #
#                                                                             #
###############################################################################
#                                                                             #
# Copyright (C) 2003 Free Software Foundation, Inc.                           #
#                                                                             #
# This script is free software; you can redistribute it and/or modify         #
# it under the terms of the GNU General Public License as published by        #
# the Free Software Foundation; either version 2, or (at your option)         #
# any later version.                                                          #
#                                                                             #
# This program is distributed in the hope that it will be useful,             #
# but WITHOUT ANY WARRANTY; without even the implied warranty of              #
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the               #
# GNU General Public License for more details.                                #
#                                                                             #
# You find more about GPL at http://www.gnu.org.                              #
#                                                                             #
###############################################################################

function stop {
   iptables -t mangle -F PREROUTING
   iptables -t mangle -F INPUT
   iptables -t mangle -F FORWARD
   iptables -t mangle -F OUTPUT
   iptables -t mangle -F POSTROUTING
   iptables -t nat    -F PREROUTING
   iptables -t nat    -F OUTPUT
   iptables -t nat    -F POSTROUTING
   iptables -t filter -F INPUT
   iptables -t filter -F FORWARD
   iptables -t filter -F OUTPUT
   iptables -t filter -P INPUT ACCEPT
   iptables -t filter -P FORWARD ACCEPT
   iptables -t filter -P OUTPUT ACCEPT
   
   rm /var/lock/firewall
}

function start {
   ##########################################################
   ################   MANGLE   PREROUTING    ################
   ##########################################################
      #Bloqueio de broadcast
      iptables -t mangle -A PREROUTING -m pkttype --pkt-type broadcast -j DROP
      
      #iptables -t mangle -A PREROUTING -p tcp --dport 622 -m limit --limit 3/m -j ACCEPT
      iptables -t mangle -A PREROUTING -p tcp --dport 10080 -m limit --limit 1/s -j ACCEPT

   ##########################################################
   ################   NAT      PREROUTING    ################
   ##########################################################
      #Proxy transparente
      iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 80 -j REDIRECT --to-port 3128
      #iptables -t nat -A PREROUTING -i ppp0 -p tcp --dport 680 -j REDIRECT --to-port 80
   
      #Direcionamentos de portas
      #Luciano
      iptables -t nat -A PREROUTING -i ppp0 -p tcp --dport 69 -j DNAT --to 10.200.5.14:80
      #Pitbull
      iptables -t nat -A PREROUTING -i ppp0 -p tcp --dport 1255 -j DNAT --to 10.200.5.8:80
      iptables -t nat -A PREROUTING -i ppp0 -p tcp --dport 111 -j DNAT --to 10.200.5.8:22

   ##########################################################
   ################   MANGLE   INPUT         ################
   ##########################################################
 
   ##########################################################
   ################   FILTER   INPUT         ################
   ##########################################################
      iptables -t filter -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
      #libera rede interna
      iptables -t filter -A INPUT -s 10.200.5.0/255.255.255.240 -j ACCEPT
      #emule tcp
      iptables -t filter -A INPUT -p tcp --dport 5662 -j ACCEPT
      #emule udp
      iptables -t filter -A INPUT -p udp --dport 5672 -j ACCEPT
      #ssh
      iptables -t filter -A INPUT -p tcp --dport 22 -j ACCEPT
      #apache
      iptables -t filter -A INPUT -p tcp --dport 80 -j ACCEPT
      #loopback
      iptables -t filter -A INPUT -i lo -j ACCEPT
      #police default
      iptables -t filter -P INPUT DROP
   
   ##########################################################
   ################   MANGLE   OUTPUT        ################
   ##########################################################
   
   ##########################################################
   ################   NAT      OUTPUT        ################
   ##########################################################
   
   ##########################################################
   ################   FILTER   OUTPUT        ################
   ##########################################################
  
   ##########################################################
   ################   MANGLE   FORWARD       ################
   ##########################################################
	
   ##########################################################
   ################   FILTER   FORWARD       ################
   ##########################################################
      #iptables -t filter -P FORWARD DROP
   
   ##########################################################
   ################   MANGLE   POSTROUTING   ################
   ##########################################################
   
   ##########################################################
   ################   NAT      POSTROUTING   ################
   ##########################################################
      iptables -t nat -A POSTROUTING -s 10.200.5.0/255.255.255.240 -j MASQUERADE
	
   #Abilitar forward, pode ser alterado em /etc/network/options ou:
   #echo "1" >/proc/sys/net/ipv4/ip_forward
	
   touch /var/lock/firewall
}

echo "iptables:"
case "$1" in
   stop)
      if [ -e /var/lock/firewall ]
      then
         echo "   Flushing rules... "
	 stop
      else
	 echo "   Firewall is already down!"
      fi
   ;;
   start)
      if ! [ -e /var/lock/firewall ]
      then
         echo "   Setting rules... "
         start
      else
         echo "   Firewall is already up!"
      fi
   ;;
   restart)
      echo "   Flushing rules... "
      stop
      echo "   Setting rules... "
      start
   ;;
   force-reload)
      echo "  Flushing rules... "
      stop
      echo "  Setting rules... "
      start
   ;;
   status)
      iptables-save
   ;;
   *)
      echo "   Invalid action \"$1\", use {start|stop|restart|force-reload|status}"
      exit 1
esac

exit 0
