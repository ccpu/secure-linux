#!/bin/bash

### define colors ###
lightred=$'\033[1;31m'  # light red
red=$'\033[0;31m'  # red
lightgreen=$'\033[1;32m'  # light green
green=$'\033[0;32m'  # green
lightblue=$'\033[1;34m'  # light blue
blue=$'\033[0;34m'  # blue
lightpurple=$'\033[1;35m'  # light purple
purple=$'\033[0;35m'  # purple
lightcyan=$'\033[1;36m'  # light cyan
cyan=$'\033[0;36m'  # cyan
lightgray=$'\033[0;37m'  # light gray
white=$'\033[1;37m'  # white
brown=$'\033[0;33m'  # brown
yellow=$'\033[1;33m'  # yellow
darkgray=$'\033[1;30m'  # dark gray
black=$'\033[0;30m'  # black
orange=$'\033[38;5;208m'
nocolor=$'\e[0m' # no color

LOGFILE='/var/log/server_hardening.log'
SSHDFILE='/etc/ssh/sshd_config'
NTP_INSTALLED='no'

@confirm() {
    local message="$*"
    local result=3
    echo -e -n "${nocolor}"
    echo ""
    echo -n "> $message (y/n) " >&2

    while [[ $result -gt 1 ]] ; do
    read -s -n 1 choice
    case "$choice" in
        y|Y ) result=0 ;;
        n|N ) result=1 ;;
    esac
    done
    echo ""
    return $result
}

@message_box(){
    length=`expr length "$*"`
    defLenght=60
    line="--"
    maxLenght=$defLenght
    declare -i spaceCont=0

    if [ $length -gt $defLenght ] ; then
        maxLenght=$length
    else
        spaceCont=($defLenght-$length)/2
    fi

    for ((i=1; i<=$maxLenght; i=i+1))
    do
        line+="-"
    done

    spaces=""
    for ((i=1; i<=$spaceCont; i=i+1))
    do
        spaces+=" "
    done


    echo $line
    echo "$spaces $*"
    echo $line
}

@info_message(){
    echo -e -n "${lightblue}"
    echo -e "$*"
    echo -e -n "${nocolor}"
}

@error_message(){
    echo -e -n "${lightred}"
    echo -e "$*"
    echo -e -n "${nocolor}"
}

@warning_message(){
    echo -e -n "${orange}"
    echo -e "$*"
    echo -e -n "${nocolor}"
}

@ucess_message(){
    echo -e -n "${lightgreen}"
    echo -e "$*"
    echo -e -n "${nocolor}"
}

@info_message_box(){
    echo -e -n "${yellow}"
    @message_box "$(date +%m.%d.%Y_%H:%M:%S) : $*" | tee -a "$LOGFILE"
    echo -e -n "${nocolor}"
}

@sucess_message_box(){
    echo -e -n "${lightgreen}"
    @message_box "$(date +%m.%d.%Y_%H:%M:%S) : $*" | tee -a "$LOGFILE"
    echo -e -n "${nocolor}"
}

@error_message_box(){
    echo -e -n "${lightred}"
    @message_box " $(date +%m.%d.%Y_%H:%M:%S) : $*" | tee -a "$LOGFILE"
    echo -e -n "${nocolor}"
}

@warning_message_box(){
    echo -e -n "${orange}"
    @message_box " $(date +%m.%d.%Y_%H:%M:%S) : $*" | tee -a "$LOGFILE"
    echo -e -n "${nocolor}"
}

@spinner()
{
    sleep $* & while [ "$(ps a | awk '{print $1}' | grep $!)" ] ; do for X in '-' '/' '|' '\'; do echo -en "\b$X"; sleep 0.1; done; done
}

@spinner_enter_continue()
{
    echo "Press enter to continue ..."
    until read -s -n 1 -t 0.01; do
    for X in '-' '/' '|' '\'; do echo -en "\b$X"; sleep 0.1; done;
    done
}

@press_enter_continue(){
    echo ""
    read -p "Press enter to continue ..."
}

@has_duplicate()
{
    FILE_PATH=$*
    variable=$(awk 'NF && $1!~/^(#|HostKey)/{print $1}' $FILE_PATH | sort | uniq -c | grep -v ' 1 ')
    local result=3

    if [ -z "$variable" ]; then
        result=1
    else
        result=0
        @error_message_box "Found duplication in '"$FILE_PATH"' file, fix the issue and try again".
    fi
    return $result
}

@is_valid_path()
{
    FILE_PATH=$*

    if [ -e $FILE_PATH ]
    then
        return 0;
    else
        return 1
    fi
}

@backup_file(){
    cp --archive $*  $*-COPY-$(date +"%Y%m%d%H%M%S") >> $LOGFILE 2>&1
    @info_message "$* file backup location : $*-COPY-$(date +"%Y%m%d%H%M%S")" | tee -a "$LOGFILE"
}

@is_line_begin_with(){
    FILE_PATH=$1
    VALUE=$2

    if grep -wq "^${VALUE}" $FILE_PATH
    then
        return 0;
    else
        return 1
    fi
}

@set_sshd_config(){
    FILE_PATH=$1
    NAME=$2

    if @is_line_begin_with $FILE_PATH "$NAME $3";then
        return 0;
    fi

    if @is_line_begin_with $FILE_PATH "$NAME";then
        sed -i "s/^$NAME .*/$NAME $3/" $SSHDFILE >> $LOGFILE
        return 0;
    fi

    if @is_line_begin_with $FILE_PATH "# $NAME";then
        sed -i "s/^# $NAME .*/$NAME $3/" $SSHDFILE >> $LOGFILE
        return 0;
    fi

    if @is_line_begin_with $FILE_PATH "#$NAME";then
        sed -i "s/^#$NAME .*/$NAME $3/" $SSHDFILE >> $LOGFILE
        return 0;
    fi

    echo "$NAME $3" >> $SSHDFILE
}