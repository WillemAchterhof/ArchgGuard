#!/usr/bin/env bash

# ==============================================================================
# Storage Handling Bootstrap
# ==============================================================================
# modules/storage_handling/bootstrap_storage_handling.sh
#
# Initializes the storage handling module and loads its components.
#
# Provides:
#   - bootstrap_storage_handling()
#
# Global variables:
#   - STORAGE_HANDLING_DIR
#   - SELECTED_USB_DISK
#   - SELECTED_INTERNAL_DISK
# ==============================================================================

# ==============================================================================
# Module Environment
# ==============================================================================

readonly STORAGE_HANDLING_DIR="$MODULES_DIR/storage_handling"

declare -g SELECTED_USB_DISK=""
declare -g SELECTED_INTERNAL_DISK=""
    
# ==============================================================================
# Module Components
# ==============================================================================

load_storage_handling_components() {
    readonly -a STORAGE_HANDLING_COMPONENTS=(
        "$STORAGE_HANDLING_DIR"              "storage_handling_run.sh"
        
        "$STORAGE_HANDLING_DIR/discovery"    "storage_discovery.sh"
        "$STORAGE_HANDLING_DIR/discovery"    "storage_classification.sh"

        "$STORAGE_HANDLING_DIR/selection"    "storage_usb.sh"
        "$STORAGE_HANDLING_DIR/selection"    "storage_internal.sh"
        "$STORAGE_HANDLING_DIR/selection"    "storage_selection.sh"
        "$STORAGE_HANDLING_DIR/selection"    "storage_validation.sh"

        #"$STORAGE_HANDLING_DIR/partitioning" "storage_partitioning.sh"
        #"$STORAGE_HANDLING_DIR/partitioning" "storage_partition_validation.sh"

        #"$STORAGE_HANDLING_DIR/formatting"   "storage_formatting.sh"
        #"$STORAGE_HANDLING_DIR/formatting"   "storage_format_validation.sh"

        #"$STORAGE_HANDLING_DIR/mounting"     "storage_mounting.sh"
    )
}

# ==============================================================================
# Bootstrap
# ==============================================================================

bootstrap_storage_handling() {
    load_storage_handling_components
    success "Completed: Storage Handling bootstrap"
}
