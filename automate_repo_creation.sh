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

# GitHub User and Token (These should be set in GitHub Secrets)
GH_USER="abhishekrana1703"  # Replace with your GitHub username
GH_TOKEN="$GH_TOKEN"        # Token stored in GitHub Secrets

# Log file
log_file="repo_creation_log.txt"

# GitHub API base URL
GH_API_URL="https://api.github.com"

# Construct the repository name
formatted_repo_name="${department_name}-${application_name}-${repo_name}"

# Function to create GitHub repository
create_github_repo() {
    echo "$(date): Creating repository: $formatted_repo_name under $GH_USER account" | tee -a $log_file
    response=$(curl -s -H "Authorization: token $GH_TOKEN" -H "Accept: application/vnd.github.v3+json" \
        -d "{\"name\": \"$formatted_repo_name\", \"visibility\": \"internal\", \"description\": \"Repository for $application_name\", \"has_issues\": true, \"has_wiki\": false}" \
        "$GH_API_URL/user/repos")

    # Check HTTP response
    if [[ $(echo "$response" | jq -r '.message') == "null" ]]; then
        echo "$(date): Repository created successfully." | tee -a $log_file
    else
        echo "$(date): Error creating repository: $response" | tee -a $log_file
        exit 1
    fi
}

# Execute the repository creation function
create_github_repo

echo "$(date): Repository creation process completed." | tee -a $log_file
