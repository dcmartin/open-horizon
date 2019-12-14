#!/bin/bash
set -o errexit

echo "--- INFO -- $0 $$ -- executed" &> /dev/stderr

# merge in branch
if [ ${GIT_MERGE:-false} = true ]; then ./.travis/git-merge.sh; fi
