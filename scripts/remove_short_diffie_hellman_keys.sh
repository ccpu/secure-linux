
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
