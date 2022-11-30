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
