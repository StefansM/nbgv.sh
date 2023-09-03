#!/bin/sh

candidate_default_branches="main master"
verbose="$V"

# Print usage message and exit with the given status code.
usage() {
    cat <<EOF
USAGE: nbgv.sh

OVERVIEW

  Call nbgv.sh from within a git repository. The repository must contain
  a file named 'version.txt' in the repository root, which must contain a
  version number in the form MINOR.MAJOR.PATCH.

  Nbgv.sh will bump the patch number by one for every commit since
  version.txt was last modified.


CONFIGURATION

  Enable verbose output by setting the environment variable 'V':

      $ V=1 nbgv.sh

  If the default branch of your git repository isn't one of
  $candidate_default_branches, you can set the default branch with the
  environment variable MAIN_BRANCH:

      $ MAIN_BRANCH=my-odly-named-main-branch nbgv.sh
EOF
}

# Print an error message, followed by the usage message and then bail out.
error() {
    echo "ERROR: $1" >&2
    echo "" >&2
    usage >&2
    exit 1
}

# Print message to stderr when the V(erbose) environment variable is set.
info() {
    [ -n "$verbose" ] && echo "$1" >&2
}

# Used to check whether a section of the version ID is a number.
is_numeric() {
    case "$1" in
        ''|*[!0-9]*)
            return 1
            ;;
        *)
            return 0
            ;;
    esac
}

# Finds the name of the main branch, given candidate branches or the MAIN_BRANCH env var.
find_main_branch() {
    # First, try the MAIN_BRANCH variable. Bail out if it doesn't exist.
    if [ -n "$MAIN_BRANCH" ]; then
        if ! git rev-parse --verify "$MAIN_BRANCH" >/dev/null 2>&1; then
            error "\$MAIN_BRANCH environment variable is '$MAIN_BRANCH', which does not exist."
        fi
        echo "$MAIN_BRANCH"
        return 0
    fi

    # Otherwise, try the common candidates.
    for branch in $candidate_default_branches; do
        if git rev-parse --verify "$branch" >/dev/null 2>&1; then
            echo "$branch"
            return 0
        fi
    done

    # Otherwise it's an error.
    error "Could not find main branch from candidates '$candidate_default_branches'."
}

# Retrieve the current branch or abort.
get_current_branch() {
    if ! current_branch="$(git symbolic-ref --short -q HEAD)"; then
        error "Could not find current branch."
    fi
    echo "$current_branch"
}

# It's possible but rare to have multiple root commits in a repo. We don't support that.
assert_only_one_root() {
    num_root_commits="$(git rev-list --all --max-parents=0 | wc -l)"
    if [ "$num_root_commits" -gt 1 ]; then
        error "There was more than one root commit. Nbgv.sh doesn't support exotic git topologies."
    fi
}

# Get the root directory of the git repository or abort.
get_root_directory() {
    if ! root_of_repo="$(git rev-parse --show-toplevel 2>/dev/null)"; then
        error "Couldn't find root of directory. Is this a git repository?"
    fi
    echo "$root_of_repo"
}


# First, we move to the root of the git directory, where version.txt should live.
root_of_repo="$(get_root_directory)"
[ "$root_of_repo" ] || exit 1
cd "$root_of_repo" || error "Error changing directory to '$root_of_repo'."


# Read the contents of version.txt
if [ ! -e version.txt ]; then
    error "version.txt not found."
fi

# Sanity check: there's only one root commit.
assert_only_one_root

version="$(cat version.txt)"

# Get last commit that changed version.txt
root_commit="$(git rev-list -1 HEAD -- version.txt 2>/dev/null)"

info "Root: $root_commit"

if [ -z "$root_commit" ]; then
    # If version.txt has never been commited, abort.
    error "version.txt has not been comitted."
else
    # Otherwise, record the commit height.
    commit_height="$(git rev-list --count --ancestry-path "$root_commit"..HEAD)"
fi

info "Version: $version"
info "Commit height: $commit_height"

# Parse version string.
major="$(echo "$version" | awk -F . '{ print $1 }')"
minor="$(echo "$version" | awk -F . '{ print $2 }')"
# Note that we discard anything after a "-" or "+" here.
patch="$(echo "$version" | awk -F '[-+.]' '{ print $3 }')"

if ! is_numeric "$major" \
    || ! is_numeric "$minor" \
    || ! is_numeric "$patch"; then
    error "All of the major, minor and patch versions must be numeric. Got '$major', '$minor' and '$patch'."
fi


info "Major: $major"
info "Minor: $minor"
info "Patch: $patch"

# Determine whether we're on a pre-release branch and add a suffix if so.
current_branch="$(get_current_branch)"
main_branch="$(find_main_branch)"
[ "$current_branch" ] || exit 1
[ "$main_branch" ] || exit 1

if [ "$main_branch" != "$current_branch" ]; then
    suffix="-dev"
fi


if [ "$commit_height" -eq 0 ]; then
    echo "$version"
else
    new_patch="$(( patch + commit_height ))"
    echo "$major.$minor.$new_patch$suffix"
fi
