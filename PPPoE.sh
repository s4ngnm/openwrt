PPPOE_USERNAME=xxxx@unifi
PPPOE_PASSWORD=xxxxxxxxxxxxxx
DNS_1=1.1.1.1
DNS_2=8.8.8.8
DNS6_1=2606:4700:4700::1111
DNS6_2=2001:4860:4860::8888
uci set network.wan.proto='pppoe'
uci set network.wan.username=$PPPOE_USERNAME
uci set network.wan.password=$PPPOE_PASSWORD
uci set network.wan.device='wan.500'
uci set network.wan.ipv6='1'
uci set network.wan.peerdns='0'
uci set network.wan.dns="$DNS_1 $DNS_2"
uci set network.wan6.proto='dhcpv6'
uci set network.wan6.device='@wan'
uci set network.wan6.peerdns='0'
uci set network.wan6.dns="$DNS6_1 $DNS6_2"
uci commit network
ifup wan
echo 'Waiting for link to initialize'
sleep 20

echo 'Updating root password'
NEWPASSWD=123
passwd <<EOF
$NEWPASSWD
$NEWPASSWD
EOF

TIMEZONE='<+08>-8'
ZONENAME='Asia/Kuala Lumpur'
echo 'Setting timezone to' $TIMEZONE
uci set system.@system[0].timezone="$TIMEZONE"
echo 'Setting zone name to' $ZONENAME 
uci set system.@system[0].zonename="$ZONENAME"
uci commit system
/etc/init.d/system reload

HOSTNAME="LiNKSYS"
uci set system.@system[0].hostname=$HOSTNAME
uci set network.lan.hostname="`uci get system.@system[0].hostname`"
uci commit system
/etc/init.d/system reload

