#!/bin/bash
# Implements some of the best practices form https://github.com/imthenachoman/How-To-Secure-A-Linux-Server
# Script to Harden Security on Ubuntu


# ###### TODO ######
# CREATE SWAP / if no swap exists, create 1 GB swap
# GOOGLE AUTH / enable 2fa using Google Authenticator https://github.com/akcryptoguy/vps-harden
# canonical-livepatch https://www.digitalocean.com/community/tutorials/how-to-keep-ubuntu-22-04-servers-updated
# test remove_short_diffie_hellman_keys
# NTP Client test /etc/ntp.conf
# Securing /proc =>  https://github.com/imthenachoman/How-To-Secure-A-Linux-Server#securing-proc
# make soure unattended-upgrades running on startup
# Lynis - Linux Security Auditing


#  echo "opssss"

function setup_environment() {
    ### define colors ###
    lightred=$'\033[1;31m'  # light red
    red=$'\033[0;31m'  # red
    lightgreen=$'\033[1;32m'  # light green
    green=$'\033[0;32m'  # green
    lightblue=$'\033[1;34m'  # light blue
    blue=$'\033[0;34m'  # blue
    lightpurple=$'\033[1;35m'  # light purple
    purple=$'\033[0;35m'  # purple
    lightcyan=$'\033[1;36m'  # light cyan
    cyan=$'\033[0;36m'  # cyan
    lightgray=$'\033[0;37m'  # light gray
    white=$'\033[1;37m'  # white
    brown=$'\033[0;33m'  # brown
    yellow=$'\033[1;33m'  # yellow
    darkgray=$'\033[1;30m'  # dark gray
    black=$'\033[0;30m'  # black
    orange=$'\033[38;5;208m'
    nocolor=$'\e[0m' # no color

    clear
    # Set Vars
    LOGFILE='/var/log/server_hardening.log'
    SSHDFILE='/etc/ssh/sshd_config'
    NTP_INSTALLED='no'
}

function begin_log() {
    # Create Log File and Begin
    echo ""
    echo -e -n "${lightcyan}"
    @message_box " $(date +%m.%d.%Y_%H:%M:%S) : Hardening Script STARTED" | tee -a "$LOGFILE"
    echo -e -n "${nocolor}"
    @spinner 2
    clear
}

@confirm() {
    local message="$*"
    local result=3
    echo -e -n "${nocolor}"
    echo ""
    echo -n "> $message (y/n) " >&2

    while [[ $result -gt 1 ]] ; do
    read -s -n 1 choice
    case "$choice" in
        y|Y ) result=0 ;;
        n|N ) result=1 ;;
    esac
    done
    echo ""
    return $result
}

@message_box(){
    length=`expr length "$*"`
    defLenght=60
    line="--"
    maxLenght=$defLenght
    declare -i spaceCont=0

    if [ $length -gt $defLenght ] ; then
        maxLenght=$length
    else
        spaceCont=($defLenght-$length)/2
    fi

    for ((i=1; i<=$maxLenght; i=i+1))
    do
        line+="-"
    done

    spaces=""
    for ((i=1; i<=$spaceCont; i=i+1))
    do
        spaces+=" "
    done


    echo $line
    echo "$spaces $*"
    echo $line
}

@info_message_box(){
    echo -e -n "${yellow}"
    @message_box "$(date +%m.%d.%Y_%H:%M:%S) : $*" | tee -a "$LOGFILE"
    echo -e -n "${nocolor}"
}

@sucess_message_box(){
    echo ""
    echo -e -n "${lightgreen}"
    @message_box "$(date +%m.%d.%Y_%H:%M:%S) : $*" | tee -a "$LOGFILE"
    echo -e -n "${nocolor}"
}

@error_message_box(){
    echo ""
    echo -e -n "${lightred}"
    @message_box " $(date +%m.%d.%Y_%H:%M:%S) : $*" | tee -a "$LOGFILE"
    echo -e -n "${nocolor}"
}

@warning_message_box(){
    echo ""
    echo -e -n "${orange}"
    @message_box " $(date +%m.%d.%Y_%H:%M:%S) : $*" | tee -a "$LOGFILE"
    echo -e -n "${nocolor}"
}

@info_message(){
    echo ""
    echo -e -n "${lightblue}"
    echo -e "$*"
    echo -e -n "${nocolor}"
}

@spinner()
{
    sleep $* & while [ "$(ps a | awk '{print $1}' | grep $!)" ] ; do for X in '-' '/' '|' '\'; do echo -en "\b$X"; sleep 0.1; done; done
}

@spinner_enter_continue()
{
    echo "Press enter to continue ..."
    until read -s -n 1 -t 0.01; do
    for X in '-' '/' '|' '\'; do echo -en "\b$X"; sleep 0.1; done;
    done
}

@press_enter_continue(){
    echo ""
    read -p "Press enter to continue ..."
}

@has_duplicate()
{
    FILE_PATH=$*
    variable=$(awk 'NF && $1!~/^(#|HostKey)/{print $1}' $FILE_PATH | sort | uniq -c | grep -v ' 1 ')
    local result=3

    if [ -z "$variable" ]; then
        result=1
    else
        result=0
        @error_message_box "Found duplication in '"$FILE_PATH"' file, fix the issue and try again".
    fi
    return $result
}

@is_valid_path()
{
    FILE_PATH=$*

    if [ -e $FILE_PATH ]
    then
        return 0;
    else
        return 1
    fi
}

@backup_file(){
    cp --archive $*  $*-COPY-$(date +"%Y%m%d%H%M%S") >> $LOGFILE 2>&1
    @info_message "$* file backup location : $*-COPY-$(date +"%Y%m%d%H%M%S")" | tee -a "$LOGFILE"
}

@is_line_begin_with(){
    FILE_PATH=$1
    VALUE=$2

    if grep -wq "^${VALUE}" $FILE_PATH
    then
        return 0;
    else
        return 1
    fi
}

@set_sshd_config(){
    FILE_PATH=$1
    NAME=$2

    if @is_line_begin_with $FILE_PATH "$NAME $3";then
        return 0;
    fi

    if @is_line_begin_with $FILE_PATH "$NAME";then
        sed -i "s/^$NAME .*/$NAME $3/" $SSHDFILE >> $LOGFILE
        return 0;
    fi

    if @is_line_begin_with $FILE_PATH "# $NAME";then
        sed -i "s/^# $NAME .*/$NAME $3/" $SSHDFILE >> $LOGFILE
        return 0;
    fi

    if @is_line_begin_with $FILE_PATH "#$NAME";then
        sed -i "s/^#$NAME .*/$NAME $3/" $SSHDFILE >> $LOGFILE
        return 0;
    fi

    echo "$NAME $3" >> $SSHDFILE
}

function initial_checks() {
    @info_message_box "INITIAL CHECKS"

    # script must be run as root
    if [[ $(id -u) -ne 0 ]] ; then printf "\n${red} Please run as root${RESTORE}\n\n" ; exit 1 ; fi

    if ! @is_valid_path $SSHDFILE ;then
        @error_message_box "Unable to find '$SSHDFILE' file!"
        echo "Ensure that SSH is configured and running, and try again."
        exit 1
    fi

    if [ ! -e /root/.ssh/authorized_keys ]; then
        echo -e -n "${red}"
        echo "The authorized_keys file could not be found."
        echo "Look like SSH Key has not been set."
        echo "The use of an SSH key is HIGHLY recommended when connecting to the server."
        echo -e -n "${nocolor}"

        if ! @confirm 'Would you like to continue without SSH Key?' ; then
            echo ""
            exit
        fi
    fi
    clear
}

######################
## UPDATE & UPGRADE ##
######################

function update_upgrade() {
    @info_message_box "INITIATING SYSTEM UPDATE"

    echo '# apt-get -y clean && apt-get -y autoclean && apt-get -y autoremove' | tee -a "$LOGFILE"
    apt-get -y clean && apt-get -y autoclean && apt-get -y autoremove

    echo '# apt-get update -y' | tee -a "$LOGFILE"
    apt-get update -y | tee -a "$LOGFILE"

    # remove grub to prevent interactive user prompt: https://tinyurl.com/y9pu7j5s
    echo '# export DEBIAN_FRONTEND=noninteractive' | tee -a "$LOGFILE"
    export DEBIAN_FRONTEND=noninteractive

    echo '# apt-get upgrade -q -y -o Dpkg::Options::="--force-confold"' | tee -a "$LOGFILE"
    apt-get upgrade -q -y -o Dpkg::Options::="--force-confold" | tee -a "$LOGFILE"

    @sucess_message_box "SYSTEM UPGRADED SUCCESSFULLY"
    @spinner 2
    clear
}

################
## USER SETUP ##
################

function add_user() {
    @info_message_box "QUERY TO CREATE NON-ROOT USER"

    echo -e -n "${lightcyan}"
    echo " Conventional wisdom would encourage you to disable root login over SSH"
    echo " because it makes accessing your server more difficult if you use password"
    echo " authentication. Since using RSA public-private key authentication is"
    echo " infinitely more secure, I will not think less of you if you choose to"
    echo " use an RSA key and continue to login as root. I am able to create a "
    echo -e " non-root user if you want me to, but it is not required. \n"

    if @confirm "Would you like to add a non-root user? "; then
        echo -e "\n"
        echo -e -n "${cyan}"
        read -p " Enter New User Name: " UNAME
        while [[ "$UNAME" =~ [^0-9A-Za-z]+ ]] || [ -z "$UNAME" ]; do echo -e "\n"
            echo -e -n "${lightred}"
            read -p " --> Please enter a ${UNAME,,} that contains only letters or numbers: " UNAME
            echo -e -n "${nocolor}"
        done
        echo -e "\n"
        echo -e -n "${yellow}"
        echo  -e " User elected to create a new user named ${UNAME,,}. \n" >> $LOGFILE 2>&1
        echo -e -n "${cyan}"
        id -u "${UNAME,,}" >> $LOGFILE > /dev/null 2>&1
        if [ $? -eq 0 ]
        then
            clear
            echo -e -n "${yellow}"
            echo " $(date +%m.%d.%Y_%H:%M:%S) : SKIPPING : User Already Exists " | tee -a "$LOGFILE"
            echo -e -n "${nocolor}"
            @spinner 5
        else
            sudo useradd --create-home --shell "/bin/bash" --groups sudo "${UNAME,,}" | tee -a "$LOGFILE"
            sudo passwd --delete "${UNAME,,}" | tee -a "$LOGFILE"

            # copy SSH keys if they exist
            if [ -e /root/.ssh/authorized_keys ]
            then
                mkdir /home/"${UNAME,,}"/.ssh
                chmod 700 /home/"${UNAME,,}"/.ssh
                # copy root SSH key to new non-root user
                cp /root/.ssh/authorized_keys /home/"${UNAME,,}"/.ssh
                # fix permissions on RSA key
                chmod 400 /home/"${UNAME,,}"/.ssh/authorized_keys
                chown "${UNAME,,}":"${UNAME,,}" /home/"${UNAME,,}" -R

                echo "$(date +%m.%d.%Y_%H:%M:%S) : SUCCESS : SSH keys were copied to ${UNAME,,}'s profile" | tee -a "$LOGFILE"
                @spinner 3
            else echo -e -n "${yellow}"
                echo "$(date +%m.%d.%Y_%H:%M:%S) : RSA keys not present for root, so none were copied." | tee -a "$LOGFILE"
            fi
            @sucess_message_box "USER SETUP IS COMPLETE"
        fi
    else
        @info_message_box "** User chose not to create a new user **"
    fi

    @spinner 5
    clear
}

################
## SSH CONFIG ##
################

function collect_sshd() {
    # Prompt for custom SSH port between 11000 and 65535
    echo -e -n "${nocolor}"
    SSHPORTWAS=$(sed -n -e '/Port /p' $SSHDFILE)

    @info_message_box "CONFIGURE SSH SETTINGS"
    echo -e -n "${orange}"
    @message_box " --> Your current SSH port number is ${SSHPORTWAS} <-- " | tee -a "$LOGFILE"
    echo -e -n "${nocolor}"

    echo -e -n "${lightcyan}"
    echo -e " By default, SSH traffic occurs on port 22, so hackers are always"
    echo -e " scanning port 22 for vulnerabilities. If you change your server to"
    echo -e " use a different port, you gain some security through obscurity.\n"

    while :; do
        echo -e -n "${cyan}"
        read -p " Enter a custom port for SSH between 11000 and 65535 or use 22: " SSHPORT
        [[ $SSHPORT =~ ^[0-9]+$ ]] || { echo -e -n "${lightred}";echo -e " --> Try harder, that's not even a number. \n";echo -e -n "${nocolor}";continue; }
        if (($SSHPORT >= 11000 && $SSHPORT <= 65535)); then break
        elif [ "$SSHPORT" = 22 ]; then break
        else
            echo -e -n "${lightred}"
            echo -e " --> That number is out of range, try again. \n"
            echo -e -n "${nocolor}"
            @error_message_box "ERROR: User entered: $SSHPORT"
        fi
    done
    # Take a backup of the existing config
    @backup_file $SSHDFILE
    @set_sshd_config $SSHDFILE Port $SSHPORT

    # Error Handling
    if [ $? -eq 0 ]
    then
        @sucess_message_box "SUCCESS : SSH port set to $SSHPORT"
        @spinner 2
    else
        @warning_message_box "ERROR: SSH Port couldn't be changed. Check log file for details."
        @press_enter_continue
    fi

    # Set SSHPORTIS to the final value of the SSH port
    SSHPORTIS=$(sed -n -e '/^Port /p' $SSHDFILE)
    clear
}

function remove_short_diffie_hellman_keys(){

    @info_message_box "Remove Short Diffie-Hellman Keys"

    echo -e -n "${lightcyan}"
    echo -e " Per Mozilla's OpenSSH guidelines for OpenSSH 6.7+,"
    echo -e " all Diffie-Hellman moduli in use should be at least 3072-bit-long"
    echo -e " The Diffie-Hellman algorithm is used by SSH to establish a secure connection."
    echo -e " The larger the moduli (key size) the stronger the encryption."
    echo -e -n "${nocolor}"

    if ! @is_valid_path /etc/ssh/moduli  ;then
        @warning_message_box "Unable to find '/etc/ssh/moduli' file, The process has been cancelled."
        @press_enter_continue
        clear
        return 0
    fi

    if @confirm "Would you like to remove short moduli?" ;then
        cp --archive /etc/ssh/moduli /etc/ssh/moduli-COPY-$(date +"%Y%m%d%H%M%S") >> $LOGFILE 2>&1
        awk '$5 >= 3071' /etc/ssh/moduli | sudo tee /etc/ssh/moduli.tmp >> $LOGFILE 2>&1
        mv /etc/ssh/moduli.tmp /etc/ssh/moduli >> $LOGFILE 2>&1
        @sucess_message_box "Short Diffie-Hellman Keys removed."
        @spinner 2
    fi
    clear
}

function prompt_rootlogin {
    # Prompt use to permit or deny root login
    ROOTLOGINP=$(sed -n -e '/^PermitRootLogin /p' $SSHDFILE)

    @info_message_box "CONFIGURE ROOT LOGIN"

    if [ -n "${UNAME,,}" ]
    then
        if [ -z "$ROOTLOGINP" ]
        then ROOTLOGINP=$(sed -n -e '/^# PermitRootLogin /p' $SSHDFILE)
        else :
        fi
        echo -e -n "${lightcyan}"
        echo -e " If you have a non-root user, you can disable root login to prevent"
        echo -e " anyone from logging into your server remotely as root. This can"
        echo -e " improve security. Disable root login if you don't need it.\n"

        @info_message "Your root login settings are: $ROOTLOGINP"  | tee -a "$LOGFILE"
        # check if ROOTLOGIN is valid
        if @confirm 'Would you like to disable root login?' ; then
            # search for root login and change to no
            @set_sshd_config $SSHDFILE PermitRootLogin no
            # Error Handling
            if [ $? -eq 0 ]
            then
                @sucess_message_box "SUCCESS : Root login disabled"
                @spinner 2
            else
                @error_message_box "ERROR: Couldn't disable root login"
                @spinner 8
            fi
        else
            @set_sshd_config $SSHDFILE PermitRootLogin yes

            if [ $? -eq 0 ]
            then
                @sucess_message_box "SUCCESS : Root login enabled"
                @spinner 2
            else
                @error_message_box "ERROR: Couldn't disable root login"
                @spinner 8
            fi

        fi
        ROOTLOGINP=$(sed -n -e '/^PermitRootLogin /p' $SSHDFILE)
        @sucess_message_box "Your root login settings are:" "$ROOTLOGINP"
        @spinner 2
    else
        @warning_message_box "Root login not changed; Becuase no non-root user was created " | tee -a "$LOGFILE"
        @spinner 5
    fi
    clear
}

function disable_passauth() {
    # query user to disable password authentication or not
    @info_message_box "PASSWORD AUTHENTICATION"

    echo -e "${lightcyan}"
    echo -e " You can log into your server using an RSA public-private key pair or"
    echo -e " a password.  Using RSA keys for login is tremendously more secure"
    echo -e " than just using a password. If you have installed an RSA key-pair"
    echo -e " and use that to login, you should disable password authentication.\n"
    echo -e "${nocolor}"
    PASSWDAUTH=$(sed -n -e '/.*PasswordAuthentication /p' $SSHDFILE)
    if [ -e /root/.ssh/authorized_keys ]
    then
        echo -e -n "${yellow}"
        # output to screen
        @info_message_box  "current password authentication ** $PASSWDAUTH ** " | tee -a "$LOGFILE"

        # check if PASSLOGIN is valid
        if @confirm 'Would you like to disable password login & require RSA key login?' ; then

            @set_sshd_config $SSHDFILE PasswordAuthentication no

            # Error Handling
            if [ $? -eq 0 ]
            then
                @sucess_message_box "SUCCESS : PassAuth set to NO"
            else
                @error_message_box "ERROR: PasswordAuthentication couldn't be changed to no :"
            fi
            @spinner 4
        else
            @set_sshd_config $SSHDFILE PasswordAuthentication yes
        fi
    else
        @warning_message_box "With no RSA key; I can't disable PasswordAuthentication."
        @spinner 5
    fi
    PASSWDAUTH=$(sed -n -e '/PasswordAuthentication /p' $SSHDFILE)
    @info_message "Your PasswordAuthentication settings are now ** $PASSWDAUTH **"
    @sucess_message_box "PASSWORD AUTHENTICATION COMPLETE"
    @spinner 5
    clear
}


################
## NTP Client ##
################

function set_ntp_client(){
        @info_message_box "NTP Client"
        echo -e -n "${lightcyan}"
        echo -e " Many security protocols leverage the time."
        echo -e " If your system time is incorrect, it could have negative impacts to your server."
        echo -e " An NTP client can solve that problem by keeping your system time in-sync with global NTP servers."
        echo -e -n "${nocolor}"

        if @confirm "Would you like setup NTP client?" ;then
            echo -e 'apt-get install ntp'  | tee -a "$LOGFILE"
            apt-get install ntp -y >> $LOGFILE 2>&1
            if [ -e /etc/ntp.conf ]
            then
                @backup_file /etc/ntp.conf

                sed -i -r -e "s/^((server|pool).*)/# \1         # commented by $(whoami) on $(date +"%Y-%m-%d @ %H:%M:%S")/" /etc/ntp.conf
                echo -e "\npool pool.ntp.org iburst         # added by $(whoami) on $(date +"%Y-%m-%d @ %H:%M:%S")" | sudo tee -a /etc/ntp.conf

                service ntp restart
                systemctl status ntp
                @spinner 4
                @sucess_message_box "NTP Client Installed."
                NTP_INSTALLED='yes'
            else
                @error_message_box "Unable to locate /etc/ntp.conf file make sure ntp installed."
                @press_enter_continue
            fi
        @spinner 2
    fi
    @spinner 2
    clear
}

################
## UFW CONFIG ##
################

function ufw_config() {
    # query user to disable password authentication or not
    @info_message_box "FIREWALL CONFIGURATION"

    echo -e -n "${lightcyan}"
    echo -e " Uncomplicated Firewall (UFW) is a program for managing a"
    echo -e " netfilter firewall designed to be easy to use. We recommend"
    echo -e " that you activate this firewall and assign default rules"
    echo -e " to protect your server."
    echo -e
    echo -e " * If you already configured UFW, choose NO to keep your existing rules"
    echo -e "${nocolor}"

    echo -e -n "${cyan}"
    while :; do
        echo -e "\n"
        read -n 1 -s -r -p " Would you like to enable UFW firewall and assign basic rules? y/n  " FIREWALLP
        if [[ ${FIREWALLP,,} == "y" || ${FIREWALLP,,} == "Y" || ${FIREWALLP,,} == "N" || ${FIREWALLP,,} == "n" ]]
        then
            break
        fi
    done
    echo -e "${nocolor}\n"

    if [ "${FIREWALLP,,}" = "Y" ] || [ "${FIREWALLP,,}" = "y" ]
    then
        echo -e -n "${nocolor}"
        # make sure ufw is installed #
        apt-get install ufw -y >> $LOGFILE 2>&1
        # add firewall rules

        ufw default allow outgoing >> $LOGFILE 2>&1
        ufw default deny incoming >> $LOGFILE 2>&1

        echo -e 'allow ssh'  | tee -a "$LOGFILE"
        ufw allow "$SSHPORT" | tee -a "$LOGFILE"

        # allow traffic out on port 53 -- DNS
        echo -e 'allow DNS calls out'  | tee -a "$LOGFILE"
        ufw allow out 53 comment 'allow DNS calls out'

        echo -e 'allow HTTP traffic out'  | tee -a "$LOGFILE"
        sudo ufw allow out http comment 'allow HTTP traffic out'

        echo -e 'allow HTTPS traffic out'  | tee -a "$LOGFILE"
        sudo ufw allow out https comment 'allow HTTPS traffic out'

        # allow traffic out on port 123 -- NTP
        if [ $NTP_INSTALLED == 'yes' ] ;then
            echo -e 'allow NTP out'  | tee -a "$LOGFILE"
            sudo ufw allow out 123 comment 'allow NTP out'
        else
            echo -e 'deny NTP out'  | tee -a "$LOGFILE"
            sudo ufw deny out 123 comment 'allow NTP out'
        fi

        if @confirm "Allow ftp" ;then
            echo -e 'allow FTP traffic out'  | tee -a "$LOGFILE"
            sudo ufw allow out ftp comment 'allow FTP traffic out'
        else
            echo -e 'deny FTP traffic out'  | tee -a "$LOGFILE"
            sudo ufw deny out ftp comment 'allow FTP traffic out'
        fi

        # allow whois
        if @confirm "Allow whois" ;then
            echo -e 'allow whois'  | tee -a "$LOGFILE"
            sudo ufw allow out whois comment 'allow whois'
        else
            echo -e 'deny whois'  | tee -a "$LOGFILE"
            sudo ufw deny out whois comment 'allow whois'
        fi

        # allow traffic out on port 68 -- the DHCP client
        # you only need this if you're using DHCP
        if @confirm "Enable DHCP" ;then
            echo -e 'allow the DHCP client to update'  | tee -a "$LOGFILE"
            sudo ufw allow out 67 comment 'allow the DHCP client to update'
            sudo ufw allow out 68 comment 'allow the DHCP client to update'
        else
            echo -e 'deny the DHCP client to update'  | tee -a "$LOGFILE"
            sudo ufw deny out 67 comment 'allow the DHCP client to update'
            sudo ufw deny out 68 comment 'allow the DHCP client to update'
        fi

    else
        @info_message_box "User chose not to setup firewall at this time"
    fi
    ufw enable
    ufw status
    @sucess_message_box "FIREWALL CONFIG COMPLETE"
    @press_enter_continue
    clear
}

################
##  Fail2Ban  ##
################


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


################
## AUTOMATIC UPDATES  ##
################

@set_51myunattended_upgrades(){
    FILE_51MYUNATTENDED_PATH="/etc/apt/apt.conf.d/51myunattended-upgrades"

    if ! @is_valid_path /etc/apt/apt.conf.d; then
        @warning_message_box "Unable to find '/etc/apt/apt.conf.d' file, The process has been cancelled."
        @press_enter_continue
        return 0
    fi

    if [ -s $FILE_51MYUNATTENDED_PATH ]; then
        @warning_message_box "The '$FILE_51MYUNATTENDED_PATH' file is not empty, The process has been cancelled."
        @press_enter_continue
        return 0
    fi

cat << EOF | sudo tee $FILE_51MYUNATTENDED_PATH
// Enable the update/upgrade script (0=disable)
APT::Periodic::Enable "1";

// Do "apt-get update" automatically every n-days (0=disable)
APT::Periodic::Update-Package-Lists "1";

// Do "apt-get upgrade --download-only" every n-days (0=disable)
APT::Periodic::Download-Upgradeable-Packages "1";

// Do "apt-get autoclean" every n-days (0=disable)
APT::Periodic::AutocleanInterval "7";

// Send report mail to root
//     0:  no report             (or null string)
//     1:  progress report       (actually any string)
//     2:  + command outputs     (remove -qq, remove 2>/dev/null, add -d)
//     3:  + trace on    APT::Periodic::Verbose "2";
APT::Periodic::Unattended-Upgrade "1";

// Automatically upgrade packages from these
Unattended-Upgrade::Origins-Pattern {
      "o=Debian,a=stable";
      "o=Debian,a=stable-updates";
      "origin=Debian,codename=${distro_codename},label=Debian-Security";
};

// You can specify your own packages to NOT automatically upgrade here
Unattended-Upgrade::Package-Blacklist {
};

// Run dpkg --force-confold --configure -a if a unclean dpkg state is detected to true to ensure that updates get installed even when the system got interrupted during a previous run
Unattended-Upgrade::AutoFixInterruptedDpkg "true";

// Perform the upgrade when the machine is running because we wont be shutting our server down often
Unattended-Upgrade::InstallOnShutdown "false";

// Send an email to this address with information about the packages upgraded.
Unattended-Upgrade::Mail "root";

// Always send an e-mail
Unattended-Upgrade::MailOnlyOnError "false";

// Remove all unused dependencies after the upgrade has finished
Unattended-Upgrade::Remove-Unused-Dependencies "true";

// Remove any new unused dependencies after the upgrade has finished
Unattended-Upgrade::Remove-New-Unused-Dependencies "true";

// Automatically reboot WITHOUT CONFIRMATION if the file /var/run/reboot-required is found after the upgrade.
Unattended-Upgrade::Automatic-Reboot "true";

// Automatically reboot even if users are logged in.
Unattended-Upgrade::Automatic-Reboot-WithUsers "true";
EOF
}

function automatic_updates() {
    @info_message_box "ENABLING AUTOMATIC UPDATES"

    echo -e -n "${lightcyan}"
cat <<- xx
 It is important to keep a server updated with the latest critical security patches and updates.
 Otherwise you're at risk of known security vulnerabilities that bad-actors could use to gain
 unauthorized access to your server.
xx
    echo -e -n "${nocolor}"
    @press_enter_continue

    # Enable automatic updates
    apt-get install unattended-upgrades apt-listchanges apticron -y

    @set_51myunattended_upgrades


    @info_message "Make sure your configuration file is okay and continue:"
    unattended-upgrade -d --dry-run
    @press_enter_continue

    # systemctl status unattended-upgrades
    @sucess_message_box "AUTOMATIC UPDATES ENABLED"
    @spinner 2
    clear
}

##################
## Restart SSHD ##
##################

function restart_sshd() {
    # prompt users to leave this session open, then create a second connection after restarting SSHD to make sure they can connect
    echo -e -n "${lightcyan}"

    @info_message_box "PROMPT USER TO RESTART SSH"
    echo -e -n "${lightcyan}"
    echo " Changes to login security will not take effect until SSHD restarts"
    echo " and firewall is enabled. You should keep this existing connection"
    echo " open while restarting SSHD just in case you have a problem or"
    echo " copied down the information incorrectly. This will prevent you"
    echo -e " from getting locked out of your server.\n"
    echo -e -n "${nocolor}"

    if @confirm 'Would you like to restart SSHD?' ; then
        # insert a pause or delay to add suspense
        systemctl restart sshd
        if [ "$FIREWALLP" = "yes" ] || [ "$FIREWALLP" = "y" ]
        then ufw --force enable | tee -a "$LOGFILE"
            echo -e " \n" | tee -a "$LOGFILE"
        else :
        fi
        # Error Handling
        if [ $? -eq 0 ]
        then
            @sucess_message_box "SUCCESS : SSHD restart complete"
            if [ "$FIREWALLP" = "yes" ] || [ "$FIREWALLP" = "y" ]
            echo -e -n "${lightgreen}"
            then echo " $(date +%m.%d.%Y_%H:%M:%S) : SUCCESS : UFW firewall enabled" | tee -a "$LOGFILE"
                echo -e "------------------------------------------------------ "
                echo -e -n "${nocolor}"
            else :
            fi
        else
            @error_message_box "ERROR: SSHD could not restart"
        fi

    else echo -e "\n"
        printf "$yellow"
        echo -e "---------------------------------------------------- "
        echo -e " *** User elected not to restart SSH at this time *** " | tee -a "$LOGFILE"
        echo -e "---------------------------------------------------- "
        echo -e -n "${nocolor}"
    fi
    @spinner 5
}

######################
## Install Complete ##
######################

function install_complete() {
    # Display important login variables before exiting script
    clear

    if @has_duplicate "/etc/ssh/sshd_config" ; then
        exit
    fi


    @warning_message_box "Seeing Ports Your Server Is Listening On:"
    ss -lntup
    @press_enter_continue

    @sucess_message_box "YOUR SERVER IS NOW SECURE"
    echo -e -n "${lightpurple}"
    @message_box "* * * Save these important login variables! * * *"
    echo -e "${yellow}"
    echo -e " --> Your SSH port for remote access is" "$SSHPORTIS"	| tee -a "$LOGFILE"
    echo -e " --> Root login settings are:" "$ROOTLOGINP" | tee -a "$LOGFILE"

    if [ -n "${UNAME,,}" ]
    then echo -e "${white} We created a non-root user named (lower case):${nocolor}" "${UNAME,,}" | tee -a "$LOGFILE"
    else echo -e "${white} A new user was not created during the setup process ${nocolor}" | tee -a "$LOGFILE"
    fi
    echo " ${white}PasswordAuthentication settings:${lightred}" "$PASSWDAUTH" | tee -a "$LOGFILE"
    if [ "${FIREWALLP,,}" = "yes" ] || [ "${FIREWALLP,,}" = "y" ]
    then echo -e "${lightcyan} --> UFW was installed and basic firewall rules were added" | tee -a "$LOGFILE"
    else echo -e "${lightcyan} --> UFW was not installed or configured" | tee -a "$LOGFILE"
    fi
    # if [ "${GETHARD,,}" = "yes" ] || [ "${GETHARD,,}" = "y" ]
    # then echo -e " --> The server and networking layer were hardened <--" | tee -a "$LOGFILE"
    # else echo -e " --> The server and networking layer were NOT hardened" | tee -a "$LOGFILE"
    # fi
    echo -e "${yellow}-------------------------------------------------------- "
    echo -e " Installation log saved to" $LOGFILE | tee -a "$LOGFILE"
    echo -e "${lightred} ---------------------------------------------------- "
    echo -e " | NOTE: Please create a new connection to test SSH | " | tee -a "$LOGFILE"
    echo -e " |       settings before you close this session     | " | tee -a "$LOGFILE"
    echo -e " ---------------------------------------------------- "
    echo -e -n "${nocolor}"
}


setup_environment
initial_checks
begin_log
update_upgrade
add_user
collect_sshd
remove_short_diffie_hellman_keys
prompt_rootlogin
disable_passauth
set_ntp_client
ufw_config
set_Fail2Ban
automatic_updates
restart_sshd
install_complete

exit
