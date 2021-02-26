#!/bin/bash

script_name="ssh_populate_same_account.tpl"
echo -e "\e[33m####################\e[39m\e[45mSTARTING USERDATA SCRIPT \e[44m$script_name\e[49m\e[33m####################\e[39m"

mkdir -p /opt/iam_helper/
cat << 'EOF' > /opt/iam_helper/ssh_populate.sh
#!/bin/bash
(
count=1
/opt/iam-authorized-keys-command | while read line
do
    username=$( echo $line | sed -e 's/^# //' -e 's/+/plus/' -e 's/=/equal/' -e 's/,/comma/' -e 's/@/at/' )
    useradd -m -s /bin/bash -k /etc/skel $username
    usermod -a -G sudo $username
    echo $username\ 'ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/$count
    chmod 0440 /etc/sudoers.d/$count
    count=$(( $count + 1 ))
    mkdir /home/$username/.ssh
    read line2
    echo $line2 >> /home/$username/.ssh/authorized_keys
    chown -R $username:$username /home/$username/.ssh
    chmod 700 /home/$username/.ssh
    chmod 0600 /home/$username/.ssh/authorized_keys
done

) > /dev/null 2>&1

/usr/sbin/sshd -i
EOF
chmod 0700 /opt/iam_helper/ssh_populate.sh

echo -e "\e[94m####################\e[39m\e[104mENDING USERDATA SCRIPT \e[47m\e[36m$script_name\e[49m\e[94m####################\e[39m"
