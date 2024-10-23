#!/bin/bash
cd /home/augol/chia-blockchain || exit 0
. /home/augol/chia-blockchain/activate
chia stop -d all
deactivate
git fetch
git checkout latest
git reset --hard FETCH_HEAD --recurse-submodules
sh install.sh
cd /home/augol/chia-blockchain/chia-blockchain-gui || exit 0
git fetch
cd ..
chmod +x /home/augol/chia-blockchain/install-gui.sh
cd /home/augol/chia-blockchain
. /home/augol/chia-blockchain/activate
/home/augol/chia-blockchain/install-gui.sh
cd /home/augol/chia-blockchain/chia-blockchain-gui || exit 0
npm run electron &
