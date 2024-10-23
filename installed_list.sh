#!/bin/bash
ls -1 /var/log/packages \
    | grep -v SBo | grep -v cmyster \
    | rev | cut -d "-" -f 4- | rev \
    | sed "s|$|-[0-9]|g" > /home/augol/gdrive/installed
scp /home/augol/gdrive/installed ikook:
