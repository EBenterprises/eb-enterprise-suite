shopt -s expand_aliases

# OMEGA® environment
source "$HOME/.config/omega/env"
alias ai="node ~/termux-agent.js"
export PATH="$HOME/bin:$PATH"

# Auto-sync to GitHub on terminal interaction
PROMPT_COMMAND="/data/data/com.termux/files/home/.git_autosync.sh; ${PROMPT_COMMAND:-}"
export PATH="$HOME:$PATH"
export PATH="${HOME}/.local/bin:${PATH}"

# --- Automated Clipboard Sync & Terminal Integration ---
export PATH="${HOME}/.local/bin:${PATH}"

# Ensure the background clipboard sync daemon runs on shell startup if not already active
if ! pgrep -f "clip_sync_daemon.sh" > /dev/null; then
    nohup "${HOME}/github-snippets/clip_sync_daemon.sh" > /dev/null 2>&1 &
fi

# --- Automated GitHub Snippet & Repo Sync Anchor ---
auto_sync_snippets() {
    local target="$HOME/github-snippets"
    if [ -d "$target" ]; then
        cd "$target" || return
        git rev-parse --is-inside-work-tree &>/dev/null && git add -A >/dev/null 2>&1
        if ! git rev-parse --is-inside-work-tree &>/dev/null && git diff-index --quiet HEAD -- 2>/dev/null; then
            git rev-parse --is-inside-work-tree &>/dev/null && git commit -m "Auto-sync snippet update: $(date '+%Y-%m-%d %H:%M:%S')" >/dev/null 2>&1
            git rev-parse --is-inside-work-tree &>/dev/null && git push origin main --force-with-lease >/dev/null 2>&1 &
        fi
        cd - >/dev/null 2>&1
    fi
}

# Trigger sync quietly in the background on shell startup
auto_sync_snippets &

# Auto-sync termux workspace on shell interaction
if [ -d "/data/data/com.termux/files/home/termux_workspace" ]; then
    (cd "/data/data/com.termux/files/home/termux_workspace" && git rev-parse --is-inside-work-tree &>/dev/null && git add . && git rev-parse --is-inside-work-tree &>/dev/null && git diff-index --quiet HEAD -- || (git rev-parse --is-inside-work-tree &>/dev/null && git commit -m "Auto-sync: $(date '+%Y-%m-%d %H:%M:%S')" && git rev-parse --is-inside-work-tree &>/dev/null && git push origin main) >/dev/null 2>&1 &)
fi


# Automated workspace sync on session closure
trap '/data/data/com.termux/files/home/termux_workspace/verify_and_deploy.sh > /dev/null 2>&1 &' EXIT
# --- Executive Spectrum Terminal Anchor ---
export WORKSPACE_DIR="${HOME}/termux_workspace"
alias ws="cd ${WORKSPACE_DIR} && python3 master_orchestrator.py"
alias wsd="cd ${WORKSPACE_DIR} && python3 dashboard_tui.py"
alias wss="cd ${WORKSPACE_DIR} && python3 snippet_store.py"
# --------------------------------------------

# ==============================================================================
# Executive Spectrum - Terminal Auto-Initialization Anchor
# EB Enterprises | Automated Terminal Environment
# ==============================================================================
if [[ -f "${HOME}/workspace_master_orchestrator.sh" ]]; then
    # Run orchestration check silently on shell startup
    bash "${HOME}/workspace_master_orchestrator.sh" start >/dev/null 2>&1
fi

# ==============================================================================
# Executive Spectrum - Global CLI Shortcut
# EB Enterprises | Automated Terminal Environment
# ==============================================================================
export PATH="$HOME/termux_workspace:$PATH"
alias execspec="${HOME}/termux_workspace/exec-spec"
export ANDROID_HOME="$HOME/android-sdk"
export ANDROID_HOME="$HOME/android-sdk"



alias orchestrator='bash ~/github-snippets/master_orchestrator.sh'
alias telemetry='bash ~/github-snippets/system_status_board.sh'
alias syncall='bash ~/github-snippets/sync_all_repos.sh'
alias verify-sys='bash ~/github-snippets/system_complete_verification.sh'
alias export-bundle='bash ~/github-snippets/system_export_bundle.sh'
alias matrix='bash ~/github-snippets/system_matrix_status.sh'
alias finalize-core='bash ~/github-snippets/system_core_finalizer.sh'
alias deploy-all='bash ~/github-snippets/system_ecosystem_deploy_all.sh'
alias dashboard='bash ~/github-snippets/master_terminal_dashboard.sh'

# EB Enterprises Executive Spectrum Aliases
alias orchestrator='bash ~/github-snippets/master_orchestrator.sh'
alias telemetry='bash ~/github-snippets/system_status_board.sh'
alias syncall='bash ~/github-snippets/sync_all_repos.sh'
alias verify-sys='bash ~/github-snippets/system_complete_verification.sh'
alias export-bundle='bash ~/github-snippets/system_export_bundle.sh'
alias matrix='bash ~/github-snippets/system_matrix_status.sh'
alias finalize-core='bash ~/github-snippets/system_core_finalizer.sh'
export PATH="$HOME/.local/bin:$PATH"
