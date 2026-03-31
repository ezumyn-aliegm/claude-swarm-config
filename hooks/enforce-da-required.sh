#!/usr/bin/env bash
# Hook: Stop (prompt-based)
# Enforces devil's advocate participation — checks that DA was invoked
# in the current phase before the coordinator concludes.
# This is a prompt-based hook that uses the LLM to verify.

# This hook is implemented as a prompt hook in settings.json, not a shell script.
# See the settings.json configuration for the prompt-based implementation.
#
# The prompt hook checks:
# 1. Was the devil's advocate agent spawned in this phase?
# 2. Were DA challenges logged with categories?
# 3. Were challenges marked as blocking or advisory?
#
# If DA was skipped, the hook blocks the Stop and instructs
# the coordinator to spawn the devil's advocate before concluding.

echo "This hook is implemented as a prompt hook in settings.json"
exit 0
