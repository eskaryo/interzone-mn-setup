#!/bin/bash

TMP_FOLDER=$(mktemp -d)
CONFIG_FILE='interzone.conf'
CONFIGFOLDER='~/.interzone'
COIN_DAEMON='/usr/local/bin/interzoned'
COIN_CLI='/usr/local/bin/interzone-cli'
COIN_REPO='https://github.com/projectinterzone/Linux-Client/archive/master.zip'
COIN_NAME='Interzone'
COIN_PORT=55675
RPCPORT=55680
USER_NAME=`whoami`


NODEIP=$(curl -s4 icanhazip.com)


RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'


function compile_node() {
  echo -e "Prepare to download $COIN_NAME files"
  cd $TMP_FOLDER
  wget -q $COIN_REPO
  unzip master.zip
  cd Linux-Client-master
  tar xvf Interzone-1.5.2.7.tar.bz2
  cd Interzone-1.5.2.7
  sudo cp * /usr/local/bin
  clear
}

function configure_systemd() {
sudo cat << EOF > /etc/systemd/system/$COIN_NAME.service
[Unit]
Description=$COIN_NAME service
After=network.target

[Service]
User=$USER_NAME
Group=$USER_NAME

Type=forking

ExecStart=$COIN_DAEMON -daemon
ExecStop=-$COIN_CLI stop

Restart=always
PrivateTmp=true
TimeoutStopSec=60s
TimeoutStartSec=10s
StartLimitInterval=120s
StartLimitBurst=5

[Install]
WantedBy=multi-user.target
EOF

  sudo systemctl daemon-reload
  sleep 3
  sudo systemctl start $COIN_NAME.service
  sudo systemctl enable $COIN_NAME.service >/dev/null 2>&1

  if [[ -z "$(sudo ps axo cmd:100 | egrep $COIN_DAEMON)" ]]; then
    echo -e "${RED}$COIN_NAME is not running${NC}, please investigate. You should start by running the following commands as root/sudo:"
    echo -e "${GREEN}systemctl start $COIN_NAME.service"
    echo -e "systemctl status $COIN_NAME.service"
    echo -e "less /var/log/syslog${NC}"
    exit 1
  fi
}


function create_config() {
  mkdir $CONFIGFOLDER >/dev/null 2>&1
  RPCUSER=$(pwgen -s 8 1)
  RPCPASSWORD=$(pwgen -s 15 1)
  cat << EOF > $CONFIGFOLDER/$CONFIG_FILE
rpcuser=$RPCUSER
rpcpassword=$RPCPASSWORD
rpcallowip=127.0.0.1
listen=1
server=1
daemon=1
port=$COIN_PORT
EOF
}

function create_key() {
  echo -e "Enter your ${RED}$COIN_NAME Masternode Private Key${NC}. Leave it blank to generate a new ${RED}Masternode Private Key${NC} for you:"
  read -e COINKEY
  if [[ -z "$COINKEY" ]]; then
  $COIN_DAEMON -daemon
  sleep 30
  if [ -z "$(ps axo cmd:100 | grep $COIN_DAEMON)" ]; then
   echo -e "${RED}$COIN_NAME server couldn not start. Check /var/log/syslog for errors.{$NC}"
   exit 1
  fi
  COINKEY=$($COIN_CLI masternode genkey)
  if [ "$?" -gt "0" ];
    then
    echo -e "${RED}Wallet not fully loaded. Let us wait and try again to generate the Private Key${NC}"
    sleep 30
    COINKEY=$($COIN_CLI masternode genkey)
  fi
  $COIN_CLI stop
fi
clear
}

function update_config() {
  sed -i 's/daemon=1/daemon=0/' $CONFIGFOLDER/$CONFIG_FILE
  cat << EOF >> $CONFIGFOLDER/$CONFIG_FILE
logintimestamps=1
maxconnections=256
bind=$NODEIP
masternode=1
masternodeaddr=$NODEIP:$COIN_PORT
masternodeprivkey=$COINKEY
addnode=207.246.65.158:55675
addnode=51.15.207.232:55675
addnode=45.76.84.32:55680
addnode=66.70.142.219:55675
addnode=45.32.173.11:55675
addnode=54.36.70.212:55675
addnode=94.177.239.53:55675
addnode=80.209.224.189:55675
EOF
}


function enable_firewall() {
  echo -e "Installing fail2ban and setting up firewall to allow ingress on port ${GREEN}$COIN_PORT${NC}"
  sudo ufw allow $COIN_PORT/tcp comment "$COIN_NAME MN port" >/dev/null
  sudo ufw allow $RPCPORT/tcp comment "$COIN_NAME RPC port" >/dev/null
  sudo ufw allow ssh comment "SSH" >/dev/null 2>&1
  sudo ufw limit ssh/tcp >/dev/null 2>&1
  sudo ufw default allow outgoing >/dev/null 2>&1
  sudo echo "y" | ufw enable >/dev/null 2>&1
  #systemctl enable fail2ban >/dev/null 2>&1
  #systemctl start fail2ban >/dev/null 2>&1
}



function get_ip() {
  declare -a NODE_IPS
  for ips in $(sudo netstat -i | awk '!/Kernel|Iface|lo/ {print $1," "}')
  do
    NODE_IPS+=($(sudo curl --interface $ips --connect-timeout 2 -s4 icanhazip.com))
  done

  if [ ${#NODE_IPS[@]} -gt 1 ]
    then
      echo -e "${GREEN}More than one IP. Please type 0 to use the first IP, 1 for the second and so on...${NC}"
      INDEX=0
      for ip in "${NODE_IPS[@]}"
      do
        echo ${INDEX} $ip
        let INDEX=${INDEX}+1
      done
      read -e choose_ip
      NODEIP=${NODE_IPS[$choose_ip]}
  else
    NODEIP=${NODE_IPS[0]}
  fi
}


function compile_error() {
if [ "$?" -gt "0" ];
 then
  echo -e "${RED}Failed to compile $COIN_NAME. Please investigate.${NC}"
  exit 1
fi
}


function checks() {
echo -e "${RED}You must run as root or a user with sudo.${NC}"

if [[ $(lsb_release -d) != *16.04* ]]; then
  echo -e "${RED}You are not running Ubuntu 16.04. Installation is cancelled.${NC}"
  exit 1
fi

#if [[ $EUID -ne 0 ]]; then
#   echo -e "${RED}$0 must be run as root or a user with root privileges.${NC}"
#   exit 1
#fi

if [ -n "$(pidof $COIN_DAEMON)" ] || [ -e "$COIN_DAEMOM" ] ; then
  echo -e "${RED}$COIN_NAME is already installed.${NC}"
  exit 1
fi
}

function prepare_system() {
echo -e "Prepare the system to install ${GREEN}$COIN_NAME${NC} master node."
echo -e "Installing required packages, it may take some time to finish.${NC}"
sudo apt-get update >/dev/null 2>&1
sudo DEBIAN_FRONTEND=noninteractive apt-get update > /dev/null 2>&1
sudo DEBIAN_FRONTEND=noninteractive apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" -y -qq upgrade >/dev/null 2>&1
sudo apt install -y software-properties-common >/dev/null 2>&1
echo -e "${GREEN}Adding bitcoin PPA repository"
sudo apt-add-repository -y ppa:bitcoin/bitcoin >/dev/null 2>&1
sudo apt-get update >/dev/null 2>&1
echo -e "Installing additional required packages, it may take some time to finish.${NC}"
sudo apt-get install -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" make software-properties-common \
build-essential libtool autoconf libssl-dev libboost-dev libboost-chrono-dev libboost-filesystem-dev libboost-program-options-dev \
libboost-system-dev libboost-test-dev libboost-thread-dev sudo automake git wget pwgen curl libdb4.8-dev bsdmainutils libdb4.8++-dev \
libminiupnpc-dev libgmp3-dev ufw fail2ban pkg-config libevent-dev unzip libdb5.3++ >/dev/null 2>&1
if [ "$?" -gt "0" ];
  then
    echo -e "${RED}Not all required packages were installed properly. Try to install them manually by running the following commands:${NC}\n"
    echo "sudo apt-get update"
    echo "sudo apt -y install software-properties-common"
    echo "sudo apt-add-repository -y ppa:bitcoin/bitcoin"
    echo "sudo apt-get update"
    echo "sudo apt install -y make build-essential libtool software-properties-common autoconf libssl-dev libboost-dev libboost-chrono-dev libboost-filesystem-dev \
libboost-program-options-dev libboost-system-dev libboost-test-dev libboost-thread-dev sudo automake git pwgen curl libdb4.8-dev \
bsdmainutils libdb4.8++-dev libminiupnpc-dev libgmp3-dev ufw fail2ban pkg-config libevent-dev unzip libdb5.3++"
 exit 1
fi

clear
}



function important_information() {
 echo
 echo -e "================================================================================================================================"
 echo -e "$COIN_NAME Masternode is up and running listening on port ${GREEN}$COIN_PORT${NC}."
 echo -e "Configuration file is: ${RED}$CONFIGFOLDER/$CONFIG_FILE${NC}"
 echo -e "Start: ${RED}systemctl start $COIN_NAME.service${NC}"
 echo -e "Stop: ${RED}systemctl stop $COIN_NAME.service${NC}"
 echo -e "VPS_IP:PORT ${RED}$NODEIP:$COIN_PORT${NC}"
 echo -e "MASTERNODE PRIVATEKEY is: ${RED}$COINKEY${NC}"
 echo -e "Please check ${GREEN}$COIN_NAME${NC} is running with the following command: ${GREEN}systemctl status $COIN_NAME.service${NC}"
 echo -e "================================================================================================================================"
}

function configure_logcleanup() {
line="* */2 * * * >/$USER_NAME/.interzone/debug.log"
(crontab -u $USER_NAME -l; echo "$line" ) | crontab -u $USER_NAME -
}

function setup_node() {
  get_ip
  create_config
  create_key
  update_config
  enable_firewall
  configure_systemd
  configure_logcleanup
  important_information
}


##### Main #####
clear

checks
prepare_system
compile_node
setup_node
