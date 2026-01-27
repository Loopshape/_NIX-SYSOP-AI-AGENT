pkg install -y proot-distro
proot-distro install ubuntu-22.04
proot-distro login ubuntu-22.04
apt update && apt install -y curl build-essential
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt install -y nodejs
npm install -g pm2
pm2 start app.js --name bitboy
pm2 save
# use a termux boot script to proot-distro login + pm2 resurrect
