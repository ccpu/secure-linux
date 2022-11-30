######################
## UPDATE & UPGRADE ##
######################

function update_upgrade() {
    @info_message_box "INITIATING SYSTEM UPDATE"

    echo '# apt-get -y clean && apt-get -y autoclean && apt-get -y autoremove' | tee -a "$LOGFILE"
    apt-get -y clean && apt-get -y autoclean && apt-get -y autoremove

    echo '# apt-get update -y' | tee -a "$LOGFILE"
    apt-get update -y | tee -a "$LOGFILE"

    # remove grub to prevent interactive user prompt: https://tinyurl.com/y9pu7j5s
    echo '# export DEBIAN_FRONTEND=noninteractive' | tee -a "$LOGFILE"
    export DEBIAN_FRONTEND=noninteractive

    echo '# apt-get upgrade -q -y -o Dpkg::Options::="--force-confold"' | tee -a "$LOGFILE"
    apt-get upgrade -q -y -o Dpkg::Options::="--force-confold" | tee -a "$LOGFILE"

    @sucess_message_box "SYSTEM UPGRADED SUCCESSFULLY"
    @spinner 2
    clear
}