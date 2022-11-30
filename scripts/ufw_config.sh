
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
