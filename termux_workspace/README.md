# Executive Spectrum Termux Workspace

A zero-dependency, highly automated development, monitoring, and snippet-management ecosystem built for Termux and Linux environments.

## Core Modules & Tools

| Tool / Script | Description |
| :--- | :--- |
| `web_ui/server.py` | Executive Spectrum Web UI dashboard with JSON status API and live metrics. |
| `dashboard_tui.py` | Interactive Terminal User Interface (TUI) for workspace control. |
| `snippet_store.py` | SQLite-backed zero-dependency snippet manager (add, list, search, delete). |
| `snippet_runner.py` | Secure temporary execution engine for stored code snippets. |
| `workspace_daemon.py` | Background supervisor daemon providing automated git staging and syncing. |
| `workspace_archive.sh` | Compressed archive utility for local backup generation. |
| `verify_and_deploy.sh` | Post-commit verification and remote sync pipeline. |
| `run_cron_scheduler.sh` | Automated log maintenance and cleanup scheduler. |

## Quick Command Aliases
- `workspace` - Launch the executive status report.
- `workspace-web` - Start the Executive Web UI server.
- `dashboard` - Launch the interactive Python TUI (`python3 dashboard_tui.py`).
- `snippets` - Manage code snippets (`python3 snippet_store.py`).
