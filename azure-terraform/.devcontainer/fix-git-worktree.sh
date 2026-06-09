#!/bin/bash
# Auto-fix git worktree paths for dev container.
# Safe to run repeatedly and never fails container startup.

set -u

WORKTREE_DIR="${PWD}"
GIT_FILE="${WORKTREE_DIR}/.git"

log() {
    echo "[fix-git-worktree] $1"
}

# Only proceed for worktrees where .git is a file.
if [ ! -f "${GIT_FILE}" ] || [ -d "${GIT_FILE}" ]; then
    log "Not a git worktree; skipping"
    exit 0
fi

CURRENT_GITDIR="$(sed -n 's/^gitdir: //p' "${GIT_FILE}" | head -n 1)"
if [ -z "${CURRENT_GITDIR}" ]; then
    log "Could not parse gitdir from .git; skipping"
    exit 0
fi

# If git already works, do nothing.
if git -c safe.directory="${WORKTREE_DIR}" -C "${WORKTREE_DIR}" rev-parse --git-dir >/dev/null 2>&1; then
    log "git already functional"
    exit 0
fi

WORKTREE_NAME="$(basename "${WORKTREE_DIR}")"
REPO_NAME="$(echo "${CURRENT_GITDIR}" | sed -n 's#.*[\\/]\([^\\/]*\)[\\/].git[\\/].*#\1#p' | head -n 1)"

if [ -z "${REPO_NAME}" ]; then
    log "Could not infer repository name from gitdir '${CURRENT_GITDIR}'; skipping"
    exit 0
fi

CANDIDATE_GITDIR="/workspaces/repos-parent/${REPO_NAME}/.git/worktrees/${WORKTREE_NAME}"

if [ ! -d "${CANDIDATE_GITDIR}" ]; then
    log "Expected worktree metadata not found at '${CANDIDATE_GITDIR}'; skipping"
    exit 0
fi

echo "gitdir: ${CANDIDATE_GITDIR}" > "${GIT_FILE}"

if git -c safe.directory="${WORKTREE_DIR}" -C "${WORKTREE_DIR}" rev-parse --git-dir >/dev/null 2>&1; then
    BRANCH="$(git -c safe.directory="${WORKTREE_DIR}" -C "${WORKTREE_DIR}" rev-parse --abbrev-ref HEAD 2>/dev/null || true)"
    log "Updated .git pointer successfully${BRANCH:+ (branch: ${BRANCH})}"
else
    log "Updated .git pointer, but git still not functional"
fi

exit 0
