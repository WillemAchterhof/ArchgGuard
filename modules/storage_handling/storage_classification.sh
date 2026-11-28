#!/usr/bin/env bash

# ==============================================================================
# Storage Classification
# ==============================================================================
# modules/storage_handling/discovery/storage_classification.sh
#
# Classifies discovered storage devices.
#
# Provides:
#   - storage_disks_classify()
#
# Requires:
#   - STORAGE_DISKS
#   - lsblk
#
# Populates:
#   - STORAGE_USB_DISKS
#   - STORAGE_INTERNAL_DISKS
#   - STORAGE_OTHER_DISKS
#
# Constraints:
#   - Definitions only; no source-time side effects.
#   - Does not discover devices.
#   - Does not select or modify devices.
# ==============================================================================

# ==============================================================================
# Classify Storage Devices
# ==============================================================================

storage_disks_classify() {

    local device
    local transport

    declare -g -a STORAGE_USB_DISKS=()
    declare -g -a STORAGE_INTERNAL_DISKS=()
    declare -g -a STORAGE_OTHER_DISKS=()

    for device in "${STORAGE_DISKS[@]}"; do

        # ----------------------------------------------------------------------
        # Read device transport
        # ----------------------------------------------------------------------

        if ! transport=$(lsblk -dnro TRAN "$device" 2>/dev/null); then
            warn "Unable to classify storage device: $device"
            STORAGE_OTHER_DISKS+=("$device")
            continue
        fi

        # ----------------------------------------------------------------------
        # Classify device
        # ----------------------------------------------------------------------

        case "$transport" in

            usb)
                STORAGE_USB_DISKS+=("$device")
                ;;

            nvme|sata|ata|sas)
                STORAGE_INTERNAL_DISKS+=("$device")
                ;;

            *)
                STORAGE_OTHER_DISKS+=("$device")
                ;;

        esac

    done

    msg "Storage classification completed"
}