
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
        read -s -p " Enter New User Password: " PASSWD
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

            useradd -m -p "$PASSWD" username "${UNAME,,}"

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