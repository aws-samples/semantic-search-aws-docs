#!/bin/bash

REPO=${1:-amazon-ec2-user-guide}

echo "REPO-Substring=$REPO"
# get number of repos of awsdocs
curl https://api.github.com/orgs/awsdocs | jq .public_repos

numRepos=$(curl https://api.github.com/orgs/awsdocs | jq .public_repos)

echo "numRepos: $numRepos"

if [ "$numRepos" = "null" ]
then
     echo "ERROR: $numRepos is NULL. Github rate limit probably exeeded. Please wait some time before trying again." 1>&2
     exit 1 # terminate and indicate error
fi

numPages=$((numRepos / 100 + 1))
echo "numRepos: $numRepos"
echo "numPages: $numPages"

# download 100 repos per page and clone the repo in the current directory
for (( c=1; c<=$numPages; c++ ))
do
echo "Page: $c / $numPages"
   curl https://api.github.com/orgs/awsdocs/repos\?per_page\=100\&page\=$c | jq '.[].clone_url' | tr -d \" | while read line || [[ -n $line ]];
   do
      if [[ "$line" == *$REPO* ]] || [[ "$line" == full ]]  ;
      then
          git clone $line || true
      fi
   done
done