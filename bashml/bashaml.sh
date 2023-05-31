#!/bin/bash

# All configurations for this script are located in the file called config.

# This script will attempt to use a number of bots, that would go over a
# formatted version of several "must-gather"s and will try to associate a
# combination of file-names and log-lines to point to a user if a certain set
# of phrases in a certain set of files means that there is a bug or not.

# At generation 0, create random bots with random test criteria which would
# go over the formatted log, create a matrix of file names and random lines
# from each file that is used, and finally give a score to those sets.
# We can then measure which bots did a good job by guessing which logs belong
# to a must-gather that was generated on a buggy environment. To do this we
# keep a simple list of a must-gather title and a true/false (bug, no bug).

# The best bots of generation 0 would then be used as the basis of the next
# Generation but with minor changes to how each one is measuring things.

# The cycle will continue until the final generation is reached.

# Disable ShellCheck's error SC1090 since I don't want to pass static URI.
# shellcheck source=/dev/null

# Get a list of folders of must-gather folders to go over:
# DATA_FOLDERS=( "$(find ./data -mindepth 1 -maxdepth 1 -type d)" )

# The current working directory.
CWD=$(pwd "$0")
export CWD

. "$CWD/config"

# Source function files.
while IFS= read -r file
do
    . "$file"
done < <(find "$CWD/functions" -name "*.sh")

# Create the workdir.
WORKDIR="$CWD/work_$(date +%s)"
mkdir "$WORKDIR"
cd "$WORKDIR" || exit

# Create initial matrix: "must-gater title" "file name(.log)" line"
create_matrix
