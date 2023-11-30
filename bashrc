

# Check if BASHRC_LOADED is set and exit if it is
[ -n "$BASHRC_LOADED" ] && return
BASHRC_LOADED=1
# echo ".bashrc loaded"


vpn-connect () {
	GATEWAY=vpn.hrz.tu-darmstadt.de
	SERVER_CERT=pin-sha256:e1pqAvLtkN7eOg0wIdMmq4nO7o6pGjnlReq1KCELelU=  # if it doesn't work anymore run without server cert, observe the output for the new server cert

	echo $VPN_PASSWORD | openconnect --protocol=anyconnect --user=$VPN_USER --passwd-on-stdin --cafile=/rootcert.crt --authgroup=extern --servercert $SERVER_CERT ${GATEWAY} --disable-ipv6
}


vpn-test () {
	echo "The following pings should be successful when the vpn connection is established"
	ping "login01.ai.tu-darmstadt.de"
}


reverse-proxy () {
	mitmdump --listen-port 9541 --mode reverse:https://login01.ai.tu-darmstadt.de:8080
}


tmux-reverse-proxy () {
  # Create a new detached session
  tmux new-session -d -s s0 'vpn-connect'

  # Create a new window running the second command
  tmux new-window -t s0:1 -n 'reverse-proxy' 'reverse-proxy'

  # Create a third window with a simple bash shell
  tmux new-window -t s0:2 -n 'bash' 'bash'

  # Attach to the tmux session
  tmux attach -t s0
}


tmux-det () {
  # Create a new detached session
  tmux new-session -d -s s0 'vpn-connect'

  # Create a new window running the second command
  tmux new-window -t s0:1 -n 'reverse-proxy' 'reverse-proxy'

  # Create a third window with a login (should close quickly)
  # tmux new-window -t s0:2 -n 'determined-ai-login' 'determined-ai-login'

  # Create a fourth window with a simple bash shell
  # tmux new-window -t s0:3 -n 'bash' 'bash'

  # Attach to the tmux session
  # tmux attach -t s0
}


det-login () {
	# sleep 2
	sshpass -p $DET_PASSWORD det user login $DET_USER
}

det-last () {
  det shell ls | awk '/RUNNING/ {print $1}' | head -n 1
}

det-attach () {
  det shell open $(det-last)
}

det-kill () {
  det shell kill $(det-last)
}

det-ssh () {
  eval $(det shell show_ssh_command $1 | grep -e ssh)
}

det-ssh-last () {
  det-ssh $(det-last)
}

det-ssh-forward () {
  kill $(lsof -t -i :9547) 
  cmd="$(det shell show_ssh_command $1 | grep -e ssh)"
  # cmd="${cmd//-tt/-t}"
  cmd="${cmd//-tt/''}"
  cmd="$cmd -L 0.0.0.0:9547:localhost:9546"

  script="$(cat <<'EOF'

    function pid_occupying_port() {
      # Convert the port to hexadecimal for searching in /proc
      hex_port=$(printf "%04X\n" $1)

      # Look for the hex port in the /proc/net/tcp file, which contains all TCP socket information
      for entry in /proc/[0-9]*/fd/*; do
        inode=$(readlink $entry | grep -oP 'socket:\[\K\d+(?=\])')
        if [[ -n $inode ]]; then
          if grep -q $inode /proc/net/tcp; then
            # Get the local address and port from /proc/net/tcp
            local_address=$(grep $inode /proc/net/tcp | awk '{print $2}')
            # Extract the port part of the local address (everything after the colon)
            local_port=$(echo $local_address | grep -oP '[A-Z0-9]+$')
            # Check if this is the port we're interested in
            if [[ $local_port == $hex_port ]]; then
              # If so, print out the PID and process name
              pid=$(echo $entry | cut -d '/' -f 3)
              process_name=$(ps -p $pid -o comm=)
              # echo "Port $your_port is being used by PID $pid ($process_name)"
              echo $pid
            fi
          fi
        fi
      done
    }

  echo PIDS: "$(pid_occupying_port 9546)"
  kill $(pid_occupying_port 9546)

  SDIR=/pfss/mlde/users/$USER
  HOME=$SDIR
  mkdir -p $SDIR/.ussh/etc/ssh

  echo -e "$SSH_PUB_KEY" > $SDIR/.ussh/etc/ssh/authorized_keys

  # enable sftp (needed for scp)
  echo -e "PubkeyAuthentication yes\nPasswordAuthentication no\nAuthorizedKeysFile $SDIR/.ussh/etc/ssh/authorized_keys\nPort 9546\nMaxStartups 10:30:60\nSubsystem sftp /usr/lib/openssh/sftp-server\n" > $SDIR/.ussh/sshd_config
  
  ssh-keygen -A -f $SDIR/.ussh

  chmod 700 $SDIR/.ussh/etc/ssh
  chmod 600 $SDIR/.ussh/etc/ssh/authorized_keys

  echo -e "launching sshd with config:\n$(cat $SDIR/.ussh/sshd_config)"
  
  /usr/sbin/sshd -D -f $SDIR/.ussh/sshd_config -h $SDIR/.ussh/etc/ssh/ssh_host_ed25519_key

EOF
  )"

  script="SSH_PUB_KEY=\"$SSH_PUB_KEY\""$'\n'"$script"

  echo "$script"
  echo -e "\n\n"
  echo "$cmd"
  echo -e "\n\n"


  # TODO: add shorter timeout
  echo "$script" | eval "$cmd" "'cat > /tmp/script.sh'" 

  eval "$cmd" 'bash /tmp/script.sh'
}


det-start () {
  det shell start --config resources.resource_pool=42_Compute --config work_dir=/pfss/mlde/users/$DET_USER $@
}


det-ssh-forward-last () {
  det-ssh-forward $(det-last)
}

det-ssh-forward-retry () {
  while true; do
    if [ -z "$(lsof -t -i :9547)" ]; then
      # port 9547 is not in use
      det-ssh-forward-last
    else
      echo "9547 occupied"
    fi
    sleep 3
  done
}

# /usr/sbin/sshd -D 

# DeterminedAI + Hessian.ai
export DET_MASTER='https://login01.ai.tu-darmstadt.de:8080/'