function disable_passauth() {
    # query user to disable password authentication or not
    @info_message_box "PASSWORD AUTHENTICATION"

    echo -e "${lightcyan}"
    echo -e " You can log into your server using an RSA public-private key pair or"
    echo -e " a password.  Using RSA keys for login is tremendously more secure"
    echo -e " than just using a password. If you have installed an RSA key-pair"
    echo -e " and use that to login, you should disable password authentication.\n"
    echo -e "${nocolor}"
    PASSWDAUTH=$(sed -n -e '/^PasswordAuthentication /p' $SSHDFILE)
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
    PASSWDAUTH=$(sed -n -e '/^PasswordAuthentication /p' $SSHDFILE)
    @info_message "Your PasswordAuthentication settings are now ** $PASSWDAUTH **"
    @sucess_message_box "PASSWORD AUTHENTICATION COMPLETE"
    @spinner 5
    clear
}