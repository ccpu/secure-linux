#!/bin/bash

source ./scripts/helper.sh
source ./scripts/initial_checks.sh
source ./scripts/update_upgrade.sh
source ./scripts/add_user.sh
source ./scripts/collect_sshd.sh
source ./scripts/remove_short_diffie_hellman_keys.sh
source ./scripts/prompt_rootlogin.sh
source ./scripts/disable_passauth.sh
source ./scripts/set_ntp_client.sh
source ./scripts/ufw_config.sh
source ./scripts/set_Fail2Ban.sh
source ./scripts/automatic_updates.sh
source ./scripts/restart_sshd.sh



function begin_log() {
    # Create Log File and Begin
    echo ""
    echo -e -n "${lightcyan}"
    @message_box " $(date +%m.%d.%Y_%H:%M:%S) : Hardening Script STARTED" | tee -a "$LOGFILE"
    echo -e -n "${nocolor}"
    @spinner 2
    clear
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
