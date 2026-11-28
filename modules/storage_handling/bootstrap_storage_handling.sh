#!/usr/bin/env bash

# ==============================================================================
# Storage Handling Bootstrap
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
# Storage Handling Environment
# ==============================================================================

storage_handling_initialization() {

    readonly STORAGE_HANDLING_DIR="$MODULES_DIR/storage_handling"

    # USB Storage Selection and Fingerprint
    declare -g SELECTED_STORAGE_USB=""
    declare -g SELECTED_STORAGE_USB_SERIAL=""
    declare -g SELECTED_STORAGE_USB_WWN=""
    declare -g SELECTED_STORAGE_USB_MODEL=""
    declare -g SELECTED_STORAGE_USB_SIZE=""
    declare -g SELECTED_STORAGE_USB_TRANSPORT=""

    # Internal Storage Selection and Fingerprint
    declare -g SELECTED_STORAGE_INTERNAL=""
    declare -g SELECTED_STORAGE_INTERNAL_SERIAL=""
    declare -g SELECTED_STORAGE_INTERNAL_WWN=""
    declare -g SELECTED_STORAGE_INTERNAL_MODEL=""
    declare -g SELECTED_STORAGE_INTERNAL_SIZE=""
    declare -g SELECTED_STORAGE_INTERNAL_TRANSPORT=""
}

# ==============================================================================
# Storage Handling Load Components
# ==============================================================================

storage_handling_load_components() {

    load_components "$STORAGE_HANDLING_DIR" "storage_discovery.sh"
    load_components "$STORAGE_HANDLING_DIR" "storage_classification.sh"
    load_components "$STORAGE_HANDLING_DIR" "storage_fingerprinting.sh"
    load_components "$STORAGE_HANDLING_DIR" "storage_verification.sh"
}

# ==============================================================================
# Storage Handling Bootstrap
# ==============================================================================

bootstrap_storage_handling() {

    storage_handling_initialization
    storage_handling_load_components

    success "Completed: Storage handling bootstrap"
}