#!/bin/sh

GITHUB_TOKEN=$1
GIPHY_API_KEY=$2

# Check required environment variables
if [ -z "$GITHUB_TOKEN" ] || [ -z "$GIPHY_API_KEY" ] || [ -z "$GITHUB_REPOSITORY" ]; then
    echo "Error: Required environment variables are not set."
    exit 1
fi

# Extract PR number
pull_request_number=$(jq --raw-output .pull_request.number "$GITHUB_EVENT_PATH")
if [ -z "$pull_request_number" ] || ! [[ "$pull_request_number" =~ ^[0-9]+$ ]]; then
    echo "Error: Invalid or missing pull request number."
    exit 1
fi
echo "PR Number - $pull_request_number"

# Fetch a random GIF from Giphy
giphy_response=$(curl -s "https://api.giphy.com/v1/gifs/random?api_key=$GIPHY_API_KEY&tag=thank%20you&rating=g")
gif_url=$(echo "$giphy_response" | jq --raw-output .data.images.downsized.url)
if [ -z "$gif_url" ] || [ "$gif_url" = "null" ]; then
    echo "Error: Failed to fetch GIF URL."
    exit 1
fi
echo "GIPHY_URL - $gif_url"

# Post a comment on the pull request
comment_response=$(curl -sX POST -H "Authorization: token $GITHUB_TOKEN" \
    -H "Accept: application/vnd.github.v3+json" \
    -d "{\"body\": \"### PR - #$pull_request_number. \n ### 🎉Thank you for this contribution! \n ![GIF]($gif_url) \"}" \
    "https://api.github.com/repos/$GITHUB_REPOSITORY/issues/$pull_request_number/comments")

comment_url=$(echo "$comment_response" | jq --raw-output .html_url)
if [ -z "$comment_url" ] || [ "$comment_url" = "null" ]; then
    echo "Error: Failed to post comment on GitHub."
    exit 1
fi
echo "COMMENT_URL - $comment_url"
