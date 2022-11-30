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
