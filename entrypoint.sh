#!/bin/bash

tmux new-session -d -s s0 'vpn-connect || (echo "exit?" && read -s -n 1)'
tmux new-window -t s0:1 -n 'reverse-proxy' 'reverse-proxy || (echo "exit?" && read -s -n 1)'
tmux new-window -t s0:2 -n 'ssh-forward' 'det-ssh-forward-retry'

det-login () {
	sshpass -p $DET_PASSWORD det user login $DET_USER
}

 # retry login three times after 1s each
det-login > /dev/null 2>&1 || \
(sleep 1 && det-login > /dev/null 2>&1) || \
(sleep 1 && det-login > /dev/null 2>&1) || \
(sleep 1 && det-login)

$@
