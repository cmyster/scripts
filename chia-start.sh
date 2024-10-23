#!/bin/bash
cd /home/augol/chia-blockchain || exit 1
. /home/augol/chia-blockchain/activate
cd /home/augol/chia-blockchain/chia-blockchain-gui || exit 1
npm run electron &
test 1
