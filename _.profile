# ~/.profile: executed by the command interpreter for login shells.
# This file is not read by bash(1), if ~/.bash_profile or ~/.bash_login
# exists.
# see /usr/share/doc/bash/examples/startup-files for examples.
# the files are located in the bash-doc package.

# the default umask is set in /etc/profile; for setting the umask
# for ssh logins, install and configure the libpam-umask package.
#umask 022

# if running bash
if [ -n "$BASH_VERSION" ]; then
    # include .bashrc if it exists
    if [ -f "$HOME/.bashrc" ]; then
	. "$HOME/.bashrc"
    fi
fi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/bin" ] ; then
    PATH="$HOME/bin:$PATH"
fi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/.local/bin" ] ; then
    PATH="$HOME/.local/bin:$PATH"
fi

# SYSTEMD via PM2 bootup
PATH="$PATH:/home/loop/.nvm/versions/node/v22.21.1/bin";
/usr/local/bin/pm2 startup systemd -u loop --hp /home/loop

#ssh-add ~/.ssh/id_rsa
DISPLAY=:0 SSH_ASKPASS=$(which ssh-askpass) setsid ssh-add ~/.ssh/id_rsa &

# First time only – create the SQLite DB and the 8 agents
# (the script does this automatically on first run)

#chmod +x "$HOME/run-ai.sh"
#"$HOME/run-ai.sh" # blocks the terminal – you can add an '&' to background it

# SETUP SCREEN :PORT
export DISPLAY=:0.0

cd ~/_
clear

