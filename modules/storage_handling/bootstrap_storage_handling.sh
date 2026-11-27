#!/usr/bin/env bash

# ==============================================================================
# Template Module Bootstrap
# ==============================================================================
# modules/storage_handling/bootstrap_storage_handling.sh
#
# Prepares the storage_handling module.
#
# Responsibilities:
#   - Establish module paths
#   - Load module components
#
# Constraints:
#   - Definitions only at top level; all work happens in bootstrap_storage_handling.
#   - Components are loaded, never executed.
#   - Inherits PROJECT_DIR, shell options and traps from the orchestrator.
# ==============================================================================

# ==============================================================================
# Module Environment
# ==============================================================================

readonly STORAGE_HANDLING_DIR="$MODULES_DIR/storage_handling"
readonly STORAGE_HANDLING_DISCOVERY="$STORAGE_HANDLING_DIR/discovery"

# ==============================================================================
# Load Module Components
# ==============================================================================

load_storage_handling_components() {
    load_components "$STORAGE_HANDLING_DISCOVERY"   "storage_discovery.sh"
    load_components "$STORAGE_HANDLING_DISCOVERY"   "storage_classification.sh"
}

# ==============================================================================
# Bootstrap
# ==============================================================================

bootstrap_storage_handling() {
    load_storage_handling_components
    success "Completed: Template bootstrap"
}
