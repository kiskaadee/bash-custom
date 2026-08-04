dep_check "lib/git.sh" "git" "gh:github-cli" "rg:ripgrep" || return 1

# 1. gitignore: Quickly appends patterns to repository's root .gitignore file
# then automatically commits and pushes the change.
gitignore() {
    # Usage: gitignore <pattern> [pattern...]
    if [ $# -eq 0 ]; then
        echo "Usage: gitignore <pattern> [pattern...]"
        return 1
    fi

    # Locate Git Root
    local GIT_ROOT
    GIT_ROOT=$(git rev-parse --show-toplevel 2> /dev/null)
    if [ -z "$GIT_ROOT" ]; then
        echo "Error: Not a Git repository."
        return 1
    fi

    local GIT_IGNORE_FILE="$GIT_ROOT/.gitignore"

    if [ ! -f "$GIT_IGNORE_FILE" ]; then
        touch "$GIT_IGNORE_FILE"
        echo "Created $GIT_IGNORE_FILE"
    fi

    if [ -s "$GIT_IGNORE_FILE" ] && [ "$(tail -c1 "$GIT_IGNORE_FILE" | wc -l)" -eq 0 ]; then
        echo "" >> "$GIT_IGNORE_FILE"
    fi

    local added_count=0
    local commit_msg_list=""

    for pattern in "$@"; do
        if rg -Fxq "$pattern" "$GIT_IGNORE_FILE"; then
            echo "Skipping '$pattern' (already in .gitignore)"
        else
            echo "$pattern" >> "$GIT_IGNORE_FILE"
            echo "Added '$pattern'"
            
            ((added_count++))
            commit_msg_list+="$pattern, "
        fi
    done

    if [ $added_count -gt 0 ]; then
        commit_msg_list="${commit_msg_list%, }"
        
        echo "Committing and pushing changes..."
        git add "$GIT_IGNORE_FILE"
        git commit -m "Add to .gitignore: $commit_msg_list"
        git push
    else
        echo "No new patterns were added."
    fi
}

# 2. gacp: Git Add, Commit, and Push shorthand
gacp() {
    # Usage: gacp <commit-message>
    if [ -z "$1" ]; then
        echo "Usage: gacp <commit-message>"
        return 1
    fi

    local commit_message="$1"
    git add -A 
    git commit -m "$commit_message"
    local branch_name
    branch_name=$(git branch --show-current)
    git push origin "$branch_name"   
    echo "Pushed to origin/$branch_name"
}

# 3. new-repo: Initializes a new directory, git repository, and pushes it to GitHub via 'gh' CLI.
new-repo() {
    # Usage: new-repo <repository-name>
    if [ -z "$1" ]; then
        echo "Usage: new-repo <repository-name>"
        return 1
    fi

    local repo_name="$1"

    mkdir -p "$repo_name"
    cd "$repo_name" || return 1

    git init -b main 
    echo "# $repo_name" > README.md
    touch .gitignore LICENSE

    git add -A && git commit -m "Initial commit"
    gh repo create "$repo_name" --public --source=. --remote=origin --push
}

