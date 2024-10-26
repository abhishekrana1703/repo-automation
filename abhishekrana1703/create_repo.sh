#!/bin/bash

# Usage: ./create_repo.sh <department_name> <application_name> <repo_name>

# Arguments
DEPARTMENT_NAME=$1
APPLICATION_NAME=$2
REPO_NAME=$3

# Combined repo name
FULL_REPO_NAME="${DEPARTMENT_NAME}-${APPLICATION_NAME}-${REPO_NAME}"
ORG_NAME="AutomateFusion"  # GitHub organization name

# Create the GitHub repository
echo "Creating GitHub repository: $FULL_REPO_NAME"
gh repo create "$ORG_NAME/$FULL_REPO_NAME" --public --confirm

# Check if the team exists
TEAM_NAME="${DEPARTMENT_NAME}-${APPLICATION_NAME}-devlead-1"
if gh api "/orgs/$ORG_NAME/teams/$TEAM_NAME" > /dev/null 2>&1; then
    echo "Adding team $TEAM_NAME to repository $FULL_REPO_NAME"
    gh api -X PUT "/orgs/$ORG_NAME/teams/$TEAM_NAME/repos/$ORG_NAME/$FULL_REPO_NAME" -f permission=push
else
    echo "Team $TEAM_NAME does not exist. Repository created without a team assignment."
fi

echo "Repository setup completed."
