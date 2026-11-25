#!/usr/bin/env bash

# ==============================================================================
# Storage Validation
# ==============================================================================
# modules/storage_handling/selection/storage_validation.sh
#
# Validates the selected internal storage device.
#
# Provides:
#   - storage_validate_internal_disk()
#
# Requires:
#   - SELECTED_INTERNAL_DISK
#   - SELECTED_USB_DISK
#
# Dependencies:
#   - lsblk
#   - warn()
#
# Constraints:
#   - Definitions only; no source-time side effects.
#   - Does not discover or select devices.
#   - Does not partition, format or mount devices.
# ==============================================================================


# ==============================================================================
# Validate Selected Internal Disk
# ==============================================================================

storage_validate_internal_disk() {

    local device_type
    local device_path

    # --------------------------------------------------------------------------
    # Check selection
    # --------------------------------------------------------------------------

    if [[ -z "$SELECTED_INTERNAL_DISK" ]]; then
        warn "No internal storage device selected"
        return 1
    fi

    # --------------------------------------------------------------------------
    # Resolve device path
    # --------------------------------------------------------------------------

    if [[ ! -b "$SELECTED_INTERNAL_DISK" ]]; then
        warn "Selected storage device does not exist or is not a block device: $SELECTED_INTERNAL_DISK"
        return 1
    fi

    device_path=$(readlink -f -- "$SELECTED_INTERNAL_DISK") || {
        warn "Unable to resolve selected storage device"
        return 1
    }

    # --------------------------------------------------------------------------
    # Verify whole-disk device
    # --------------------------------------------------------------------------

    device_type=$(lsblk -dnro TYPE "$device_path" 2>/dev/null) || {
        warn "Unable to determine selected storage device type"
        return 1
    }

    if [[ "$device_type" != "disk" ]]; then
        warn "Selected device is not a whole disk: $device_path"
        return 1
    fi

    # --------------------------------------------------------------------------
    # Protect installer USB
    # --------------------------------------------------------------------------

    if [[ -n "$SELECTED_USB_DISK" && -b "$SELECTED_USB_DISK" ]]; then

        local installer_device

        installer_device=$(readlink -f -- "$SELECTED_USB_DISK") || {
            warn "Unable to resolve installer USB device"
            return 1
        }

        if [[ "$device_path" == "$installer_device" ]]; then
            warn "Selected disk is the installer USB and cannot be used"
            return 1
        fi

    fi

    msg "Selected storage device validated: $device_path"

    return 0
}
