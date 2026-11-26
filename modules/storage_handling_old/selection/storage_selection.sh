#!/usr/bin/env bash

# ==============================================================================
# Storage Selection
# ==============================================================================
# modules/storage_handling/selection/storage_selection.sh
#
# Displays available internal disks and handles user selection.
#
# Provides:
#   - storage_select_internal_disk()
#
# Requires:
#   - AG_STORAGE_AVAILABLE_INTERNAL_DISKS
#
# Populates:
#   - SELECTED_INTERNAL_DISK
#
# Dependencies:
#   - msg()
#   - warn()
#
# Constraints:
#   - Definitions only; no source-time side effects.
#   - Does not discover or classify devices.
#   - Does not partition, format or mount devices.
#   - Does not perform final device validation.
# ==============================================================================


# ==============================================================================
# Select Internal Storage
# ==============================================================================

storage_select_internal_disk() {

    local device
    local selection
    local -i index=1
    local -i choice

    SELECTED_INTERNAL_DISK=""

    # --------------------------------------------------------------------------
    # Check available devices
    # --------------------------------------------------------------------------

    if (( ${#AG_STORAGE_AVAILABLE_INTERNAL_DISKS[@]} == 0 )); then
        warn "No internal storage devices available for selection"
        return 1
    fi

    # --------------------------------------------------------------------------
    # Display available devices
    # --------------------------------------------------------------------------

    msg "Available internal storage devices:"

    for device in "${AG_STORAGE_AVAILABLE_INTERNAL_DISKS[@]}"; do
        printf '  %d) %s\n' "$index" "$device"
        (( index += 1 ))
    done

    # --------------------------------------------------------------------------
    # Read user selection
    # --------------------------------------------------------------------------

    printf '\nSelect installation disk (1-%d): ' \
        "${#AG_STORAGE_AVAILABLE_INTERNAL_DISKS[@]}"

    if ! read -r selection; then
        warn "Storage selection cancelled"
        return 1
    fi

    # --------------------------------------------------------------------------
    # Validate selection format
    # --------------------------------------------------------------------------

    if [[ ! "$selection" =~ ^[0-9]+$ ]]; then
        warn "Invalid selection"
        return 1
    fi

    choice="$selection"

    if (( choice < 1 || choice > ${#AG_STORAGE_AVAILABLE_INTERNAL_DISKS[@]} )); then
        warn "Selection out of range"
        return 1
    fi

    # --------------------------------------------------------------------------
    # Store selection
    # --------------------------------------------------------------------------

    SELECTED_INTERNAL_DISK="${AG_STORAGE_AVAILABLE_INTERNAL_DISKS[choice-1]}"

    msg "Selected installation disk: $SELECTED_INTERNAL_DISK"
}
