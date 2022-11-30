@set_51myunattended_upgrades(){
    FILE_51MYUNATTENDED_PATH="/etc/apt/apt.conf.d/51myunattended-upgrades"

    if ! @is_valid_path /etc/apt/apt.conf.d; then
        @warning_message_box "Unable to find '/etc/apt/apt.conf.d' file, The process has been cancelled."
        @press_enter_continue
        return 0
    fi

    if [ -s $FILE_51MYUNATTENDED_PATH ]; then
        @warning_message_box "The '$FILE_51MYUNATTENDED_PATH' file is not empty, The process has been cancelled."
        @press_enter_continue
        return 0
    fi

cat << EOF | sudo tee $FILE_51MYUNATTENDED_PATH
// Enable the update/upgrade script (0=disable)
APT::Periodic::Enable "1";

// Do "apt-get update" automatically every n-days (0=disable)
APT::Periodic::Update-Package-Lists "1";

// Do "apt-get upgrade --download-only" every n-days (0=disable)
APT::Periodic::Download-Upgradeable-Packages "1";

// Do "apt-get autoclean" every n-days (0=disable)
APT::Periodic::AutocleanInterval "7";

// Send report mail to root
//     0:  no report             (or null string)
//     1:  progress report       (actually any string)
//     2:  + command outputs     (remove -qq, remove 2>/dev/null, add -d)
//     3:  + trace on    APT::Periodic::Verbose "2";
APT::Periodic::Unattended-Upgrade "1";

// Automatically upgrade packages from these
Unattended-Upgrade::Origins-Pattern {
      "o=Debian,a=stable";
      "o=Debian,a=stable-updates";
      "origin=Debian,codename=${distro_codename},label=Debian-Security";
};

// You can specify your own packages to NOT automatically upgrade here
Unattended-Upgrade::Package-Blacklist {
};

// Run dpkg --force-confold --configure -a if a unclean dpkg state is detected to true to ensure that updates get installed even when the system got interrupted during a previous run
Unattended-Upgrade::AutoFixInterruptedDpkg "true";

// Perform the upgrade when the machine is running because we wont be shutting our server down often
Unattended-Upgrade::InstallOnShutdown "false";

// Send an email to this address with information about the packages upgraded.
Unattended-Upgrade::Mail "root";

// Always send an e-mail
Unattended-Upgrade::MailOnlyOnError "false";

// Remove all unused dependencies after the upgrade has finished
Unattended-Upgrade::Remove-Unused-Dependencies "true";

// Remove any new unused dependencies after the upgrade has finished
Unattended-Upgrade::Remove-New-Unused-Dependencies "true";

// Automatically reboot WITHOUT CONFIRMATION if the file /var/run/reboot-required is found after the upgrade.
Unattended-Upgrade::Automatic-Reboot "true";

// Automatically reboot even if users are logged in.
Unattended-Upgrade::Automatic-Reboot-WithUsers "true";
EOF
}

function automatic_updates() {
    @info_message_box "ENABLING AUTOMATIC UPDATES"

    echo -e -n "${lightcyan}"
cat <<- xx
 It is important to keep a server updated with the latest critical security patches and updates.
 Otherwise you're at risk of known security vulnerabilities that bad-actors could use to gain
 unauthorized access to your server.
xx
    echo -e -n "${nocolor}"
    @press_enter_continue

    # Enable automatic updates
    apt-get install unattended-upgrades apt-listchanges apticron -y

    @set_51myunattended_upgrades


    @info_message "Make sure your configuration file is okay and continue:"
    unattended-upgrade -d --dry-run
    @press_enter_continue

    # systemctl status unattended-upgrades
    @sucess_message_box "AUTOMATIC UPDATES ENABLED"
    @spinner 2
    clear
}