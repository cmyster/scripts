#!/usr/bin/bash
date
uptime
cat <<EOF

######################################################################
#                          Welcome CT user!                          #
#                                                                    #
# You are probably here to compile a new version.                    #
#                                                                    #
# In order to start compiling, you need to run the built-tomcat.sh   #
# script in the buildtools folder of the branch that you are in.     #
# The default folder for 'trunk' can be accessed by entering 'bh'.   #
#                                                                    #
# For any other branch, for example a pre-deploy branch or a version #
# for a specific client, navigate to the branch and link the script  #
# to the buildtools folder. For example:                             #
# cd svn.ct/versions/mizrahi/buildtools/                             #
# ln -s /home/ct/scripts/build-tomcat.sh .                           #
#                                                                    #
#         For ANY questions, read the options one more time!         # 
#      To print this message again, write help and press enter.      #
######################################################################


EOF
