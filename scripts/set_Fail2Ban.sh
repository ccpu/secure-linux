@create_Fail2Ban_jail_file(){
    JAIL_LOCAL_PATH="/etc/fail2ban/jail.local"

    if [ -s $JAIL_LOCAL_PATH ]; then
        @warning_message_box "The '/etc/fail2ban/jail.local' file is not empty, The process has been cancelled."
        @press_enter_continue
        return 0
    fi

cat <<EOF >> $JAIL_LOCAL_PATH
[DEFAULT]
# the IP address range we want to ignore
ignoreip = 127.0.0.1/8 [LAN SEGMENT]

EOF


    if @confirm "Would you like Fail2Ban send email regarding its activitis?"; then
        read -p "Who to send e-mail to: " DEST_EMAIL
        read -p "Who is the email from: " SENDER_EMAIL

cat <<EOF >> $JAIL_LOCAL_PATH
# who to send e-mail to
destemail = $DEST_EMAIL

# who is the email from
sender = $SENDER_EMAIL

# since we're using exim4 to send emails
mta = mail

# get email alerts
action = %(action_mwl)s
EOF

    fi
}

@create_Fail2Ban_ssh_local(){
    if [ ! -e /etc/fail2ban/jail.d ]
    then
        @warning_message_box "Unable to find '/etc/fail2ban/jail.d' directory, The process has been cancelled."
        @press_enter_continue
        return 0
    fi

    if [ -s /etc/fail2ban/jail.d/ssh.local ]; then
        @warning_message_box "The '/etc/fail2ban/jail.d/ssh.local' file is not empty, The process has been cancelled."
        @press_enter_continue
        return 0
    fi

cat << EOF | sudo tee /etc/fail2ban/jail.d/ssh.local
[sshd]
enabled = true
banaction = ufw
port = ssh
filter = sshd
logpath = %(sshd_log)s
maxretry = 5
EOF
}

function set_Fail2Ban(){
    @info_message_box "Setting up Fail2Ban"


    echo -e -n "${lightcyan}"
    cat <<- xx
 Fail2ban monitors the logs of your applications (like SSH and Apache)
 to detect and prevent potential intrusions.
 It will monitor network traffic/logs and prevent intrusions by blocking
 suspicious activity (e.g. multiple successive failed connections in a short time-span).
xx
    echo -e -n "${nocolor}"

    @press_enter_continue

    apt-get install fail2ban -y >> $LOGFILE 2>&1

    if [ -e /etc/fail2ban ]
    then
        @create_Fail2Ban_jail_file
        @create_Fail2Ban_ssh_local


        fail2ban-client start
        fail2ban-client reload
        fail2ban-client add sshd # This may fail on some systems if the sshd jail was added by default
        fail2ban-client status
        fail2ban-client status sshd
        @press_enter_continue
        @sucess_message_box "Fail2Ban CONFIG COMPLETE"
        @spinner 2
    else
        @warning_message_box "Unable to find '/etc/fail2ban' directory, The process has been cancelled."
        @press_enter_continue
    fi
    clear
}
