function collect_sshd() {
    # Prompt for custom SSH port between 11000 and 65535
    echo -e -n "${nocolor}"
    SSHPORTWAS=$(sed -n -e '/^Port /p' $SSHDFILE)

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