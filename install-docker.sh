#!/bin/bash

LINK_LCLIB='https://raw.githubusercontent.com/clementlvx/LcLib-shell/master/LcLib-shell.sh'

Main() {
    source ./LcLib-shell.sh $*
    LcLib_install_docker
    LcLib_install_dockerCompose
}

if test -f ./LcLib-shell.sh; then
    EXIST="1"
    Main $*
else
    if [[ `wget -S --spider "${LINK_LCLIB}" 2>&1 | grep 'HTTP/1.1 200 OK'` ]]; then
        echo -e -ne "\033[0;35mDOWNLOAD LIBRARY - \033[0m \r"
        sh -c "wget ${LINK_LCLIB}" 2> /dev/null
        sleep 5
        echo -e -ne "\033[0;32mDOWNLOAD LIBRARY - DONE\033[0m \r"
        echo -ne '\n'
        EXIST="0"
        Main $*
    fi
fi
if [ "$EXIST" != "1" ] && [[ ! "${*}" =~ "-keep" ]]; then rm -rf ./LcLib-shell.sh; exit 0; fi
