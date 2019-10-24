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
nocolor=$'\e[0m' # no color

# Used this while testing color output
echo -e " ${lightred}Light Red${nocolor}"
echo -e " ${red}Red${nocolor}"
printf " ${lightgreen}Light Green${nocolor}\n"
printf " ${green}Green${nocolor}\n"
printf " ${lightblue}Light Blue${nocolor}\n"
printf " ${blue}Blue${nocolor}\n"
printf " ${lightpurple}Light Purple${nocolor}\n"
printf " ${purple}Purple${nocolor}\n"
printf " ${lightcyan}Light Cyan${nocolor}\n"
printf " ${cyan}Cyan${nocolor}\n"
printf " ${lightgray}Light Gray${nocolor}\n"
printf " ${white}White${nocolor}\n"
printf " ${brown}Brown${nocolor}\n"
printf " ${yellow}Yellow${nocolor}\n"
printf " ${darkgray}Dark Gray${nocolor}\n"
printf " ${black}Black${nocolor}\n"
printf " ${cyan}Cyan\n"
figlet " hello $(whoami)" -f small
printf "Text in ${red}red${nocolor}, ${white}white${nocolor} and ${blue}blue${nocolor}.\n"
printf " ${nocolor}${nocolor}\n"
