#!/usr/bin/env bash

# ==============================================================================
# Internal Storage Identification
# ==============================================================================
# modules/storage_handling/selection/storage_internal.sh
#
# Identifies available internal storage devices.
#
# Provides:
#   - storage_identify_internal_disks()
#
# Requires:
#   - AG_STORAGE_INTERNAL_DISKS
#   - SELECTED_USB_DISK
#
# Populates:
#   - AG_STORAGE_AVAILABLE_INTERNAL_DISKS
#
# Dependencies:
#   - msg()
#
# Constraints:
#   - Definitions only; no source-time side effects.
#   - Does not discover or classify devices.
#   - Does not display selection menus.
#   - Does not select a target disk.
#   - Does not modify storage devices.
# ==============================================================================


# ==============================================================================
# Identify Internal Storage
# ==============================================================================

storage_identify_internal_disks() {

    local device

    declare -g -a AG_STORAGE_AVAILABLE_INTERNAL_DISKS=()

    for device in "${AG_STORAGE_INTERNAL_DISKS[@]}"; do

        # ----------------------------------------------------------------------
        # Exclude installer USB, if present
        # ----------------------------------------------------------------------

        [[ "$device" == "$SELECTED_USB_DISK" ]] && continue

        AG_STORAGE_AVAILABLE_INTERNAL_DISKS+=("$device")

    done

    msg "Available internal storage devices: ${#AG_STORAGE_AVAILABLE_INTERNAL_DISKS[@]}"
}
