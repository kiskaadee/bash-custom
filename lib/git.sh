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

# 4. gh-remote: Defensively creates a GitHub repo via GH CLI and attaches it to current git 'origin'
gh-remote() {
    # Usage: gh-remote [-f|--force] [--private] <repository-name>
    local force=false
    local visibility="--public"
    local repo_name=""

    while [[ "$#" -gt 0 ]]; do
        case "$1" in
            -f|--force)
                force=true
                shift
                ;;
            --private)
                visibility="--private"
                shift
                ;;
            --public)
                visibility="--public"
                shift
                ;;
            -h|--help)
                echo "Usage: gh-remote [-f|--force] [--private] <repository-name>"
                return 0
                ;;
            *)
                if [[ -z "$repo_name" ]]; then
                    repo_name="$1"
                    shift
                else
                    echo "Error: Unknown argument '$1'" >&2
                    return 1
                fi
                ;;
        esac
    done

    if [[ -z "$repo_name" ]]; then
        echo "Usage: gh-remote [-f|--force] [--private] <repository-name>" >&2
        return 1
    fi

    # 1. Must be inside a Git repository
    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        echo "Error: Current directory is not a Git repository." >&2
        return 1
    fi

    # 2. Check existing 'origin' remote
    local existing_origin
    existing_origin=$(git remote get-url origin 2>/dev/null || true)

    if [[ -n "$existing_origin" && "$force" != true ]]; then
        echo "Error: Remote 'origin' is already set to '$existing_origin'." >&2
        echo "Use -f or --force to overwrite." >&2
        return 1
    fi

    # 3. Create remote repository using GH CLI
    echo "Creating GitHub repository '$repo_name' ($visibility)..."
    local repo_url
    if ! repo_url=$(gh repo create "$repo_name" "$visibility" 2>/dev/null); then
        echo "Error: Failed to create GitHub repository '$repo_name'." >&2
        return 1
    fi

    if [[ -z "$repo_url" ]]; then
        local gh_user
        gh_user=$(gh api user --jq '.login' 2>/dev/null || true)
        if [[ -n "$gh_user" ]]; then
            repo_url="https://github.com/$gh_user/$repo_name.git"
        fi
    fi

    # 4. Update or Add remote origin
    if [[ -n "$existing_origin" && "$force" == true ]]; then
        git remote set-url origin "$repo_url"
        echo "✅ Updated remote 'origin' -> $repo_url"
    else
        git remote add origin "$repo_url"
        echo "✅ Added remote 'origin' -> $repo_url"
    fi

    # 5. Copy URL to Wayland clipboard if available
    if command -v wl-copy >/dev/null 2>&1 && [[ -n "$repo_url" ]]; then
        printf "%s" "$repo_url" | wl-copy
        echo "📋 URL copied to clipboard: $repo_url"
    fi
}


