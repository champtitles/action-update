#!/bin/bash -ex

export DIRECTORY=${DIRECTORY:-.update}
export FILE=${FILE:-variables.tf}
export PATTERN=${PATTERN:-lkajsdflkajsdflkjsadf}
export BRANCH=${BRANCH:-develop}

if [ -z "${SSH_PRIVATE_KEY}" ]; then
    echo "SSH_PRIVATE_KEY is required to clone private repositories"
    exit 1
fi

if [ -z "${TARGET_REPO}" ]; then
    echo "TARGET_REPO must be set to an SSH git clone URL"
    exit 1
fi

if [ -z "${TARGET_KEY}" ]; then
    export TARGET_KEY=$(echo ${GITHUB_REPOSITORY} | sed -e 's|.*/||')
fi

if [ -z "${TARGET_VALUE}" ]; then
    export TARGET_KEY=${GITHUB_SHA}
fi

# enable cloning of private repositories
mkdir -p ~/.ssh
ssh-keyscan -t rsa github.com >>~/.ssh/known_hosts
eval $(ssh-agent)
ssh-add - <<<"${SSH_PRIVATE_KEY}"

# update git repository
git clone -b ${BRANCH} ${TARGET_REPO} ${DIRECTORY}
cd ${DIRECTORY}
sed ${FILE} ${TARGET_KEY} ${PATTERN}
git commit -m "${TARGET_KEY} ${TARGET_VALUE}"

# retry logic to mitigate race conditions between multiple repositories
for i in 1 2 3 4 5; do git push origin ${BRANCH} && break || git pull && sleep 5; done
