#!/bin/bash
script_name="iam-authorized-keys-command.tpl"
echo -e "\e[33m####################\e[39m\e[45mSTARTING USERDATA SCRIPT \e[44m$script_name\e[49m\e[33m####################\e[39m"

mkdir -p /opt/golang/src/iam-authorized-keys-command/
cat << EOF > /opt/golang/src/iam-authorized-keys-command/main.go
        ${authorized_command_code}
EOF
DEBIAN_FRONTEND=noninteractive
sudo apt-get install -y golang
export GOPATH=/opt/golang

COMMAND_DIR=$GOPATH/src/iam-authorized-keys-command

mkdir -p $COMMAND_DIR
cd $COMMAND_DIR

export GOCACHE=/tmp/

go get ./...
go build -ldflags "-X main.iamGroup=${bastion_allowed_iam_group}" -o /opt/iam_helper/iam-authorized-keys-command ./main.go

echo -e "\e[94m####################\e[39m\e[104mENDING USERDATA SCRIPT \e[47m\e[36m$script_name\e[49m\e[94m####################\e[39m"
