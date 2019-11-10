#!/bin/bash


#-------  confguração inicial/Atualização  ----------------

cp /usr/share/doc/apt/examples/sources.list   /etc/apt
apt-get update -y
apt-get upgrade -y
apt-get dist-upgrade -y
ifconfig eth1 up

# ----------- Atualizado ------------------

#-------------- Instalação dos Serviços ------------------- 

#--- 1.NTP ---

apt-get install ntp -y
/etc/init.d/ntp start

#--- 2.SSH ---

apt-get install openssh-server
cp /etc/ssh/sshd_config sshd_config-bkp
nano /etc/ssh/sshd_config
#OBS: onde tiver “without-password”, substituir por “yes”
/etc/init.d/ssh restart


#--- 3.DHCP ---

           #---- Atribuindo ip na eth1 para funcionamento do dhcp-server ----
           nano /etc/network/interfaces
	   #---- Adiciona no final ----
	   #auto eth1
	   #iface eth1 inet static
	   #address 10.0.0.1
	   #netmask 255.255.255.0
	   #network 10.0.0.0
	   #broadcast 10.0.0.255


apt-get install isc-dhcp-server
cp  /etc/dhcp/dhcpd.conf dhcpd.conf-bkp
nano /etc/dhcp/dhcpd.conf

	#OBS: apaga tudo ----------
	#ddns-update-style none;
	#default-lease-time 600;
	#max-lease-time 7200;
	#authoritative;
	#log-facility local7;

	#subnet 10.0.0.0 netmask 255.255.255.0 {
	#range 10.0.0.10 10.0.0.200;
	#option routers 10.0.0.1;
	#option domain-name-servers 8.8.8.8,8.8.4.4;
	#option domain-name "estacio.br";

/etc/init.d/isc-dhcp-server restart

#--- 4.FTP ---

apt-get install proftpd
nano /etc/proftpd/proftpd.conf
nano /etc/ftpusers #(comentar #root para ter acesso direto)
adduser aluno01
	#OBS: Comentar dento do arquivo -----------
	#Servername “nome”
	#DefaultRoot  ~  (escrever abaixo disso) obs: Tirar o # do DefaultRoot 
	#Rootlogin off
	#UseFtpUsers on
	#User ftp

/etc/init.d/proftpd restart

#--- 5.SQUID ---

apt-get install squid3
cp /etc/squid3/squid.conf   /etc/squid3/squid.conf-bkp
cat /etc/squid3/squid.conf-bkp | grep -v ^# | uniq > /etc/squid3/squid.conf 
nano /etc/squid3/squid.conf

	#OBS:(onde tiver (deny) trocar por (allow) e depois reiniciar o serviço ------
 
/ect/init.d/squid3 restart

#-----  Bloquear site Uol
 
vim /etc/squid3/squid.conf
 
#acl uol dstdomain .globo.com.br por causa do https
#http_acess deny uol
#salva, fecha e reinicia o serviço

/ect/init.d/squid3 restart










