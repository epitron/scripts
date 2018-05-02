#!/bin/bash

# Fail hard and fast if any intermediate command pipeline fails
set -e

NETNS=latency-network
SERVER_IF=veth-server
CLIENT_IF=veth-client
# The delay in uSecs
DELAY=1000000

function help {
    echo "$0 <Server IP> <Client IP> [CMD [ARGS ....]]"
    echo ""
    echo "    Server IP: IP address assigned to the server"
    echo "    Client IP: IP address assigned to the client, Must be"
    echo "               in the same /24 subnet as the server"
    echo "    CMD/ARGS:  The command/server to execute at the other"
    echo "               end of the high latency link, DEFAULT=/bin/sh"
}

if [ "$1" == "-h" ]; then
    help
    exit 0
fi

if [ "$1" == "" ]; then
    echo "Error: Please specify an IPv4 Address for the server"
    echo
    help
    exit 1
fi
if [ "$2" == "" ]; then
    echo "Error: Please specify an IPv4 Address for the client"
    echo
    help
    exit 1
fi
SERVER_IP=$1
CLIENT_IP=$2
shift 2

if [ "$1" == "" ]; then
    echo "No command specified, using /bin/sh"
    CMD=/bin/sh
    ARGS=""
else
    CMD=$1
    shift
    ARGS=$*
fi

# Create the networking pair
ip li add $SERVER_IF type veth peer name $CLIENT_IF
# Automatically clean up interfaces on script exit
trap "ip li del $CLIENT_IF" EXIT

# Add a 100ms Delay
tc qdisc add dev $CLIENT_IF root netem delay $DELAY
tc qdisc add dev $SERVER_IF root netem delay $DELAY

# Assign the requested IP addresses
ip ad add $CLIENT_IP/24 dev $CLIENT_IF

# Bring the interfaces up in the correct order
ip li set $CLIENT_IF up

# Create a net namespace and set it up with the server interface
ip netns add $NETNS
trap "ip li del $CLIENT_IF; ip netns del $NETNS" EXIT
ip li set $SERVER_IF netns $NETNS

# Set IP networking in the container
ip netns exec $NETNS ip ad add $SERVER_IP/24 dev $SERVER_IF
ip netns exec $NETNS ip li set $SERVER_IF up
ip netns exec $NETNS ip ro add default via $CLIENT_IP

# Execute the command in the namespace
ip netns exec $NETNS $CMD $ARGS