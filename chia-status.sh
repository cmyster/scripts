#!/bin/bash
if pgrep chia_wallet &> /dev/null
then
    cd /home/augol/chia-blockchain
    . ./activate
    chia farm summary | head -n 11 > /home/augol/.chia-status
else
    sed -i 's/: Farming/: Not Farming!/' /home/augol/.chia-status
fi
