
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
            @info_message "NTP Status"
            service ntp status | cat
            @press_enter_continue
            @sucess_message_box "NTP Client Installed."
            NTP_INSTALLED='yes'
        else
            @error_message_box "Unable to locate /etc/ntp.conf file make sure ntp installed."
        fi
    fi

    clear
}