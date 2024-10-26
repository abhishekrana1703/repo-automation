#!/bin/bash

# Input Parameters from GitHub Actions workflow
department_name=$1
application_name=$2
repo_name=$3
webhook_url=$4  # New parameter for webhook URL

# Check for input parameters
if [[ -z "$department_name" || -z "$application_name" || -z "$repo_name" ]]; then
    echo "Error: Missing required parameters." | tee -a repo_creation_log.txt
    exit 1
fi

# GitHub Organization and Token (These should be set in GitHub Secrets)
GH_ORG="abhishekrana1703"  # Ensure this is the correct organization name
GH_TOKEN="$GH_TOKEN"

# Log file
log_file="repo_creation_log.txt"

# GitHub API base URL
GH_API_URL="https://api.github.com"

# Construct the repository name
formatted_repo_name="${department_name}-${application_name}-${repo_name}"

# Function to send response to webhook
send_response_to_webhook() {
    response_data=$1
    curl -s -X POST "$webhook_url" -H "Content-Type: application/json" -d "$response_data"
}

# Function to create GitHub repository
create_github_repo() {
    echo "$(date): Creating repository: $formatted_repo_name under $GH_ORG organization" | tee -a $log_file
    response=$(curl -v -s -H "Authorization: token $GH_TOKEN" -H "Accept: application/vnd.github.v3+json" \
        -d "{\"name\": \"$formatted_repo_name\", \"visibility\": \"public\", \"description\": \"Repository for $application_name\", \"has_issues\": true, \"has_wiki\": false}" \
        "$GH_API_URL/orgs/$GH_ORG/repos")

    # Parse response to get repository URL and status
    repo_url=$(echo "$response" | jq -r '.html_url')
    if [[ "$repo_url" != "null" ]]; then
        echo "$(date): Repository created successfully." | tee -a $log_file

        # Prepare response data
        response_data="{\"repository_name\": \"$formatted_repo_name\", \"repository_url\": \"$repo_url\", \"status\": \"success\"}"

        # Send response to the webhook
        send_response_to_webhook "$response_data"
    else
        error_message=$(echo "$response" | jq -r '.message')
        echo "$(date): Error creating repository: $response" | tee -a $log_file

        # Prepare error data
        response_data="{\"status\": \"failure\", \"error\": \"$error_message\"}"

        # Send error response to the webhook
        send_response_to_webhook "$response_data"
        exit 1
    fi
}

# Create the repository
create_github_repo

echo "$(date): Repository creation process completed." | tee -a $log_file
