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

            sudo passwd -l root
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