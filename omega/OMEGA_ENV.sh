#!/data/data/com.termux/files/usr/bin/bash

OMEGA_ROOT="$HOME/omega"

if [ ! -d "$OMEGA_ROOT" ]; then
    echo "OMEGA® project not found: $OMEGA_ROOT"
    return 1 2>/dev/null || exit 1
fi

cd "$OMEGA_ROOT" || return 1 2>/dev/null || exit 1

# Load project-local environment variables.
if [ -f "$OMEGA_ROOT/.env.local" ]; then
    while IFS='=' read -r key value; do
        case "$key" in
            ""|\#*) continue ;;
        esac

        case "$key" in
            OPENAI_API_KEY|OMEGA_GPT_MODEL)
                export "$key=$value"
                ;;
        esac
    done < "$OMEGA_ROOT/.env.local"
fi

export OMEGA_ROOT
export OMEGA_GPT_MODEL="${OMEGA_GPT_MODEL:-gpt-5}"

echo "OMEGA® environment loaded."
echo "OMEGA_ROOT=$OMEGA_ROOT"
echo "OMEGA_GPT_MODEL=$OMEGA_GPT_MODEL"

if [ -n "${OPENAI_API_KEY:-}" ]; then
    echo "OPENAI_API_KEY=CONFIGURED"
else
    echo "OPENAI_API_KEY=NOT CONFIGURED"
fi
