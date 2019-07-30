#!/bin/bash
set -e

function configure_openvpn {
    CONFIG_DIR=$1
    CLIENT_CONFIG="${CONFIG_DIR}/client.conf"
    CREDENTIALS_CONFIG="${CONFIG_DIR}/credentials.conf"
    TA_KEY="${CONFIG_DIR}/ta.key"

    echo "${ca_crt}" > ${CONFIG_DIR}/ca.crt
    echo "${client_crt}" > ${CONFIG_DIR}/client.crt
    echo "${client_key}" > ${CONFIG_DIR}/client.key

    cat <<EOF > ${CLIENT_CONFIG}
client
dev tun
proto ${proto}
remote ${host} ${port}
resolv-retry infinite
nobind
persist-key
persist-tun
comp-lzo
verb 3
ca ca.crt
cert client.crt
key client.key
EOF

    if [ ! -z "${username}" ] || [ ! -z "${password}" ]
    then
      echo ${username} > ${CREDENTIALS_CONFIG}
      echo ${password} >> ${CREDENTIALS_CONFIG}

      echo "auth-user-pass ${CREDENTIALS_CONFIG}" >> ${CLIENT_CONFIG}
    fi

    if [ ! -z "${tls_key}" ]
    then
      echo "${tls_key}" > ${TA_KEY}

      echo "tls-auth ${TA_KEY} ${tls_direction}" >> ${CLIENT_CONFIG}
    fi
}

case "$OSTYPE" in
  linux*)
    echo "Configuring for Ubuntu"

    configure_openvpn "/etc/openvpn"

    service openvpn start client > /dev/null 2>&1
    sleep 5

    if ifconfig | grep tun0 > /dev/null
    then
      echo "VPN connection succeeded"
    else
      echo "VPN connection failed!"
      exit 1
    fi
    ;;
  darwin*)
    echo "Configuring for Mac OS"
 
    configure_openvpn "."

    sudo openvpn --config client.conf > /dev/null 2>&1 &

    sleep 5

    if ifconfig -l | grep utun0 > /dev/null
    then
      echo "VPN connection succeeded"
    else
      echo "VPN connection failed!"
      exit 1
    fi
    ;;
  *)
    echo "Unknown operative system: $OSTYPE, exiting"
    exit 1
    ;;
esac
