#!/bin/bash

# === CONFIGURATION ===
AZURE_ORG="vigneshr0540"
AZURE_PROJECT_ID="115bad1c-bcc7-4a15-a937-e9afc4ef8313"  # <- Replace with actual Project ID
PAT="IOBtf49siOnaMs7gIUlrm1sO9Sz1H7NYaigRijFwJG8tB5Bbdh8rJQQJ99BDACAAAAAbL04UAAASAZDO3onr"                # <- Replace with actual PAT
BASE_DIR="C:\Users\vignesh.r\Downloads\psn\repos"  # Change path if needed

# === Validate Inputs ===
if [[ -z "$AZURE_ORG" || -z "$AZURE_PROJECT_ID" || -z "$PAT" || "$PAT" == "your-pat-token-here" ]]; then
    echo "❌ Please set valid values for AZURE_ORG, AZURE_PROJECT_ID, and PAT."
    exit 1
fi

# === Setup Logging ===
LOG_FILE="$BASE_DIR/repo_creation_log.txt"
touch "$LOG_FILE" || { echo "❌ Cannot write to $LOG_FILE"; exit 1; }
echo "🔧 Starting repository creation: $(date)" > "$LOG_FILE"

# === Function to get remote URL if repo exists ===
get_existing_repo_remote_url() {
    local repo_name="$1"
    local response=$(curl -s -u ":$PAT" \
        "https://dev.azure.com/$AZURE_ORG/$AZURE_PROJECT_ID/_apis/git/repositories/$repo_name?api-version=7.1")

    if echo "$response" | grep -q '"remoteUrl"'; then
        echo "$response" | grep -o '"remoteUrl":"[^"]*"' | sed 's/"remoteUrl":"\(.*\)"/\1/'
    else
        echo ""
    fi
}

# === Function to create and push repo ===
create_and_push_repo() {
    local folder_name="$1"
    local repo_name=$(echo "$folder_name" | tr '.' '_')
    local folder_path="$BASE_DIR/$folder_name"

    echo "📁 Processing folder: $folder_name"

    if [ ! -d "$folder_path" ]; then
        echo "⚠️  Skipping $folder_name (not a directory)"
        return
    fi

    echo "🔍 Checking if repo '$repo_name' exists in project '$AZURE_PROJECT_ID'..."
    remote_url=$(get_existing_repo_remote_url "$repo_name")

    if [[ -z "$remote_url" ]]; then
        echo "🌐 Creating repo '$repo_name'"
        create_response=$(curl -s -u ":$PAT" \
            -X POST \
            -H "Content-Type: application/json" \
            -d "{\"name\": \"$repo_name\", \"project\": {\"id\": \"$AZURE_PROJECT_ID\"}}" \
            "https://dev.azure.com/$AZURE_ORG/_apis/git/repositories?api-version=7.1")

        if echo "$create_response" | grep -q "InvalidArgumentValueException"; then
            echo "❌ Failed to create repo $repo_name" | tee -a "$LOG_FILE"
            echo "$create_response" | tee -a "$LOG_FILE"
            return
        fi

        remote_url=$(echo "$create_response" | grep -o '"remoteUrl":"[^"]*"' | sed 's/"remoteUrl":"\(.*\)"/\1/')
        if [[ -z "$remote_url" ]]; then
            echo "❌ Could not extract remote URL for $repo_name" | tee -a "$LOG_FILE"
            echo "$create_response" | tee -a "$LOG_FILE"
            return
        fi

        echo "✅ Repo created: $remote_url"
    else
        echo "🔁 Repo already exists: $remote_url"
    fi

    # Add PAT to remote URL
    auth_remote_url="https://$AZURE_ORG:$PAT@dev.azure.com/$AZURE_ORG/$AZURE_PROJECT_ID/_git/$repo_name"

    cd "$folder_path" || { echo "❌ Failed to cd into $folder_path"; return; }

    # Initialize or reset Git repo
    if [ -d ".git" ]; then
        echo "🔄 Git repo exists, resetting origin"
        git remote remove origin 2>/dev/null
    else
        echo "🟢 Initializing git repo"
        git init
    fi

    # Set the remote URL
    git remote add origin "$auth_remote_url"

    # Commit any changes (if any)
    git add .
    git commit -m "Initial commit for $repo_name" || echo "⚠️ Nothing to commit"

    # Push to the correct branch (main or master)
    echo "🚀 Pushing repo $repo_name..."
    git push -u origin main 2>/dev/null || git push -u origin master 2>/dev/null || git push -u origin --all

    if [ $? -eq 0 ]; then
        echo "✅ Repo successfully pushed: $repo_name" | tee -a "$LOG_FILE"
    else
        echo "❌ Error pushing repo $repo_name" | tee -a "$LOG_FILE"
    fi

    echo "----------------------------------------"
}

# === Main Loop ===
echo "🔁 Searching folders under: $BASE_DIR"
for folder in "$BASE_DIR"/*; do
    if [ -d "$folder" ]; then
        folder_name=$(basename "$folder")
        create_and_push_repo "$folder_name" 2>&1 | tee -a "$LOG_FILE"
    fi
done

echo "🎉 All repositories processed!"
echo "📝 Log saved at: $LOG_FILE"