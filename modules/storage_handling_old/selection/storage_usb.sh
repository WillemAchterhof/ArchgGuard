
#!/usr/bin/env bash

# ==============================================================================
# USB Storage Identification
# ==============================================================================
# modules/storage_handling/selection/storage_usb.sh
#
# Identifies the USB device containing the running installer.
#
# Provides:
#   - storage_identify_installer_usb()
#
# Requires:
#   - AG_STORAGE_USB_DISKS
#
# Populates:
#   - SELECTED_USB_DISK
#
# Dependencies:
#   - lsblk
#   - msg()
#   - warn()
#
# Constraints:
#   - Definitions only; no source-time side effects.
#   - Does not discover or classify devices.
#   - Does not display selection menus.
#   - Does not partition, format or mount devices.
# ==============================================================================

# ==============================================================================
# Identify Installer USB
# ==============================================================================

storage_identify_installer_usb() {

    local device
    local source_device
    local parent_device
    local resolved_device

    SELECTED_USB_DISK=""

    # --------------------------------------------------------------------------
    # Identify the device containing the root filesystem
    # --------------------------------------------------------------------------

    source_device=$(findmnt -nro SOURCE / 2>/dev/null) || {
        warn "Unable to identify installer root filesystem"
        return 1
    }

    [[ -n "$source_device" ]] || {
        warn "Installer root filesystem source is empty"
        return 1
    }

    # --------------------------------------------------------------------------
    # Resolve source to its parent disk
    # --------------------------------------------------------------------------

    parent_device=$(lsblk -sno PKNAME "$source_device" 2>/dev/null | tail -n 1)

    if [[ -z "$parent_device" ]]; then
        warn "Unable to identify installer USB parent device"
        return 1
    fi

    resolved_device="/dev/$parent_device"

    # --------------------------------------------------------------------------
    # Verify device belongs to discovered USB disks
    # --------------------------------------------------------------------------

    for device in "${AG_STORAGE_USB_DISKS[@]}"; do

        if [[ "$device" == "$resolved_device" ]]; then
            SELECTED_USB_DISK="$device"
            msg "Identified installer USB: $SELECTED_USB_DISK"
            return 0
        fi

    done

    warn "Installer device was not found in discovered USB disks"
    return 1
}
