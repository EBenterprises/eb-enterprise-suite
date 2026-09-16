#!/usr/bin/env bash
# ==============================================================================
# Executive Spectrum - Modular Plugin Architecture & Extension Loader
# EB Enterprises | Automated Terminal Environment
# ==============================================================================

PLUGIN_DIR="${HOME}/.workspace_plugins"
ENABLED_DIR="${HOME}/.workspace_plugins/enabled"
LOG_FILE="${HOME}/.workspace_daemon.log"

init_plugin_system() {
    mkdir -p "$PLUGIN_DIR" "$ENABLED_DIR"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [PLUGIN] Initialized plugin directories." >> "$LOG_FILE"
}

register_plugin() {
    local plugin_name="$1"
    local plugin_path="$PLUGIN_DIR/$plugin_name"
    
    if [[ -f "$plugin_path" ]]; then
        chmod +x "$plugin_path"
        ln -sf "$plugin_path" "$ENABLED_DIR/$plugin_name"
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [PLUGIN] Registered and enabled: $plugin_name" >> "$LOG_FILE"
    else
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [PLUGIN] Error: Plugin $plugin_name not found." >> "$LOG_FILE"
    fi
}

load_plugins() {
    if [[ -d "$ENABLED_DIR" ]]; then
        for plugin in "$ENABLED_DIR"/*; do
            if [[ -x "$plugin" ]]; then
                echo "[$(date '+%Y-%m-%d %H:%M:%S')] [PLUGIN] Executing: $(basename "$plugin")" >> "$LOG_FILE"
                source "$plugin"
            fi
        done
    fi
}

init_plugin_system
load_plugins
