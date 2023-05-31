#!/bin/bash
rsync -ruhv --progress --exclude=debug/ --include=*/ --include=*t?z --exclude=* rsync://slackware.org.uk/people/alien/multilib/current/ ./
