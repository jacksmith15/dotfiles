#!/usr/bin/env bash

if [[ "$#" -eq 0 ]]; then
    echo "Usage is "$0" TITLE [TARGET_BRANCH]"
    echo "  Requires Github CLI (https://hub.github.com/)"
    exit 0
fi

TITLE=$1

if [[ "$#" -eq 2 ]]; then
    TARGET=$2
else
    TARGET=develop
fi

FEATURE_CHECKS=$(sed -e '/# Feature checklist/,/# Release checklist/!d' .github/pull_request_template.md | grep -v '# Release checklist')

RELEASE_CHECKS=$(sed -e '/# Release checklist/,/\$/!d' .github/pull_request_template.md)

if [[ "$TARGET" == "develop" ]]; then
    CHECKS=$FEATURE_CHECKS
elif [[ "$TARGET" == "master" ]]; then
    CHECKS=$RELEASE_CHECKS
else
    echo "Unsupported target branch $TARGET"
    exit 1
fi

CHANGES="# What has changed

$(git diff $TARGET CHANGELOG.md | grep '^+\*' | sed 's/^+//g')
"

PR_MESSAGE="# $TITLE

$CHANGES

$CHECKS
"

hub pull-request -b "$TARGET" -m \""$PR_MESSAGE"\"
