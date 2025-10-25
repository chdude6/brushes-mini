#!/bin/bash

# Configuration
REPO_DIR="brushes"  # Change this if your repo is in a different folder
FILE_NAME="foo"
COMMIT_MESSAGE="Add or remove 'a' to foo file"
START_DATE="2024-01-01T00:00:00"  # Starting at January 1, 2024
END_DATE="2024-10-25T23:59:59"    # Until October 25, 2024
NUM_COMMITS_PER_DAY_MIN=6         # Minimum number of commits per day
NUM_COMMITS_PER_DAY_MAX=8         # Maximum number of commits per day
GITHUB_PAT="a1b2c3"  # Hardcoded GitHub Personal Access Token (PAT)

# Check if the repository exists
if [ ! -d "$REPO_DIR" ]; then
    echo "Cloning repository: ilovelasagne/brushes"
    git clone https://github.com/ilovelasagne/brushes.git "$REPO_DIR" || { echo "Failed to clone repository. Press any key to exit."; read -n 1 -s; exit 1; }
fi

# Navigate to the repository directory
cd "$REPO_DIR" || { echo "Failed to change directory to $REPO_DIR. Press any key to exit."; read -n 1 -s; exit 1; }

# Function to randomly add or remove 'a's
function random_change {
    local day_date=$1
    local num_changes=$(shuf -i $NUM_COMMITS_PER_DAY_MIN-$NUM_COMMITS_PER_DAY_MAX -n 1)  # Random number between min and max
    local action

    # Perform the random changes
    for ((i = 0; i < num_changes; i++)); do
        action=$((RANDOM % 2))  # Random action: 0 = add, 1 = remove
        if [[ $action -eq 0 ]]; then
            # Add 'a' to the file
            echo -n "a" >> "$FILE_NAME"
        else
            # Remove one 'a' from the file if it exists
            if [ -f "$FILE_NAME" ]; then
                sed -i '' -e 's/a//' "$FILE_NAME" || { echo "Failed to remove 'a' from $FILE_NAME"; exit 1; }
            else
                echo "File $FILE_NAME does not exist, creating it..."
                touch "$FILE_NAME"
            fi
        fi

        # Check if there is a lock file and remove it
        if [ -f .git/index.lock ]; then
            echo "Removing stale lock file..."
            rm -f .git/index.lock
        fi

        # Stage all changes (including untracked files)
        git add -A || { echo "Failed to add files to staging. Press any key to exit."; read -n 1 -s; exit 1; }

        # Commit with the custom date
        git commit --date="$day_date" -m "$COMMIT_MESSAGE" || { echo "Failed to commit changes. Press any key to exit."; read -n 1 -s; exit 1; }
    done
}

# Export function for parallel execution
export -f random_change

# Generate the days in the range from 2024-01-01 to 2024-10-25
current_date="$START_DATE"
while [[ "$current_date" < "$END_DATE" ]]; do
    # Format the date string for git commit
    formatted_date=$(date -d "$current_date" +"%Y-%m-%dT%H:%M:%S")

    # Run the random_change function in the background for this date (using parallel or background processes)
    random_change "$formatted_date" &

    # Increment the date by one day
    current_date=$(date -d "$current_date + 1 day" +"%Y-%m-%dT%H:%M:%S")
done

# Wait for all background processes to finish
wait

# Push the changes to GitHub
echo "Pushing all commits to GitHub..."
git push https://$GITHUB_PAT@github.com/ilovelasagne/brushes.git main || { echo "Failed to push changes to GitHub. Press any key to exit."; read -n 1 -s; exit 1; }

echo "Successfully made random commits from January 1 to October 25, 2024!"
echo "Press any key to exit."
read -n 1 -s  # Keep terminal open after completion
