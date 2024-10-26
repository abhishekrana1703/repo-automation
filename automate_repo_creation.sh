#!/bin/bash

# Input Parameters from GitHub Actions workflow
department_name=$1
application_name=$2
repo_name=$3

# Check for input parameters
if [[ -z "$department_name" || -z "$application_name" || -z "$repo_name" ]]; then
    echo "Error: Missing required parameters." | tee -a repo_creation_log.txt
    exit 1
fi

# GitHub Organization and Token (These should be set in GitHub Secrets)
GH_ORG="abhishekrana1703"
GH_TOKEN="$GH_TOKEN"  # Use the token stored in GitHub Secrets

# Log file
log_file="repo_creation_log.txt"

# GitHub API base URL
GH_API_URL="https://api.github.com"

# Construct the repository name
formatted_repo_name="${department_name}-${application_name}-${repo_name}"

# Function to create GitHub repository
create_github_repo() {
    echo "$(date): Creating repository: $formatted_repo_name under $GH_ORG organization" | tee -a $log_file
    response=$(curl -s -H "Authorization: token $GH_TOKEN" -H "Accept: application/vnd.github.v3+json" \
        -d "{\"name\": \"$formatted_repo_name\", \"visibility\": \"internal\", \"description\": \"Repository for $application_name\", \"has_issues\": true, \"has_wiki\": false}" \
        "$GH_API_URL/orgs/$GH_ORG/repos")

    # Check HTTP response
    if [[ $(echo "$response" | jq -r '.message') == "null" ]]; then
        echo "$(date): Repository created successfully." | tee -a $log_file
    else
        echo "$(date): Error creating repository: $response" | tee -a $log_file
        exit 1
    fi
}

# Function to assign team to repository
assign_team() {
    team_slug=$1
    role=$2

    echo "$(date): Assigning $team_slug team with $role access to $formatted_repo_name" | tee -a $log_file
    response=$(curl -s -H "Authorization: token $GH_TOKEN" -H "Accept: application/vnd.github.v3+json" \
        -X PUT \
        "$GH_API_URL/orgs/$GH_ORG/teams/$team_slug/repos/$GH_ORG/$formatted_repo_name" \
        -d "{\"permission\": \"$role\"}")

    # Check HTTP response
    if [[ $(echo "$response" | jq -r '.message') == "null" ]]; then
        echo "$(date): Team $team_slug assigned successfully." | tee -a $log_file
    else
        echo "$(date): Error assigning team $team_slug: $response" | tee -a $log_file
    fi
}

# Check for dev and devlead teams
dev_team_slug="azrgh-team-${application_name}-dev-1"
devlead_team_slug="azrgh-team-${application_name}-devlead-1"

echo "$(date): Checking for existing teams..." | tee -a $log_file

# Check if dev team exists
dev_team_response=$(curl -s -H "Authorization: token $GH_TOKEN" "$GH_API_URL/orgs/$GH_ORG/teams/$dev_team_slug")
dev_team_exists=$(echo "$dev_team_response" | jq -r ".slug == \"$dev_team_slug\"")
echo "Dev team response: $dev_team_response" | tee -a $log_file  # Log response for debugging

# Check if devlead team exists
devlead_team_response=$(curl -s -H "Authorization: token $GH_TOKEN" "$GH_API_URL/orgs/$GH_ORG/teams/$devlead_team_slug")
devlead_team_exists=$(echo "$devlead_team_response" | jq -r ".slug == \"$devlead_team_slug\"")
echo "Devlead team response: $devlead_team_response" | tee -a $log_file  # Log response for debugging

# Create the repository
create_github_repo

# Assign teams if they exist
if [[ "$dev_team_exists" == "true" ]]; then
    assign_team "$dev_team_slug" "push"
else
    echo "$(date): Dev team $dev_team_slug not found, skipping assignment" | tee -a $log_file
fi

if [[ "$devlead_team_exists" == "true" ]]; then
    assign_team "$devlead_team_slug" "admin"
else
    echo "$(date): Devlead team $devlead_team_slug not found, skipping assignment" | tee -a $log_file
fi

echo "$(date): Repository creation process completed." | tee -a $log_file
