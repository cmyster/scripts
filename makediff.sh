#!/bin/bash
/usr/bin/vimdiff $1 $2 <<EOF

:TOhtml

:w ${3}
:qa
EOF

