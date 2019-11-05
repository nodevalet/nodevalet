#!/bin/bash
# this file is just a collection of useful notes and code and may be ignored

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
    nocolor=$'\e[0m' # no color

# hide a command's output
echo -e "You're not missing anything" > /dev/null 2>&1

# echo precise date and time
echo -e " $(date +%m.%d.%Y_%H:%M:%S) : THIS IS HAPPENING NOW "


# simple prompt for yes or no
function prompt_for_confirmation() {

    echo -e " Are you sure you would like to do this thing? \n"
    
    while :; do
        echo -e "\n"
        read -n 1 -s -r -p " ${lightred}Would you like to do the thing? y/n " INPUT
        if [[ ${INPUT,,} == "y" || ${INPUT,,} == "Y" || ${INPUT,,} == "N" || ${INPUT,,} == "n" ]]
        then
            break
        fi
    done

    if [ "${INPUT,,}" = "Y" ] || [ "${INPUT,,}" = "y" ]
    then echo -e " Do some stuff "
    else echo -e " Do some other stuff "
    fi
}

# manipulate display of text strings
function text_demo() {
PROJECT='HELium'
# assign PROJECTt to be a title case version of PROJECT (Helium)
PROJECTt=$(echo $PROJECT | awk '{print toupper(substr($0,0,1))tolower(substr($0,2))}')
# display in all lowercase (helium)
echo -e "${PROJECT,,}"
# invert case of first character (hELium)
echo -e "${PROJECTl~}"
# invert case of all characters (helIUM)
echo -e "${PROJECTl~~}"
# capitalize all characters (HELIUM)
echo -e "${PROJECTl^^}"

echo $PROJECT | awk '{print toupper(substr($0,0,1))tolower(substr($0,2))}'


}