pkg update -y
pkg install -y nodejs
mkdir -p ~/.npm-global
npm config set prefix "$HOME/.npm-global"
export PATH="$HOME/.npm-global/bin:$PATH"
npm install -g pm2
export PM2_HOME="$HOME/.pm2"
pm2 start app.js --name bitboy
pm2 save
# create termux boot script (see above) to resurrect on reboot
