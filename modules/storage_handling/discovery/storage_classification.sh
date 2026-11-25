#!/usr/bin/env bash

# ==============================================================================
# Storage Classification
# ==============================================================================
# modules/storage_handling/discovery/storage_classification.sh
#
# Classifies discovered storage devices.
#
# Provides:
#   - storage_classify_disks()
#
# Requires:
#   - AG_STORAGE_DISKS
#   - lsblk
#
# Populates:
#   - AG_STORAGE_DISK_CLASS
#   - AG_STORAGE_DISK_TRANSPORT
#   - AG_STORAGE_DISK_REMOVABLE
#   - AG_STORAGE_USB_DISKS
#   - AG_STORAGE_INTERNAL_DISKS
#   - AG_STORAGE_OTHER_DISKS
# ==============================================================================


# ==============================================================================
# Classify Storage Devices
# ==============================================================================

storage_classify_disks() {

    local device
    local transport
    local removable

    declare -gA AG_STORAGE_DISK_CLASS=()
    declare -gA AG_STORAGE_DISK_TRANSPORT=()
    declare -gA AG_STORAGE_DISK_REMOVABLE=()

    declare -g -a AG_STORAGE_USB_DISKS=()
    declare -g -a AG_STORAGE_INTERNAL_DISKS=()
    declare -g -a AG_STORAGE_OTHER_DISKS=()

    for device in "${AG_STORAGE_DISKS[@]}"; do

        # ----------------------------------------------------------------------
        # Read device properties
        # ----------------------------------------------------------------------

        if ! read -r transport removable < <(
            lsblk -dnro TRAN,RM "$device" 2>/dev/null
        ); then
            warn "Unable to classify storage device: $device"
            continue
        fi

        transport="${transport:-unknown}"
        removable="${removable:-unknown}"

        AG_STORAGE_DISK_TRANSPORT["$device"]="$transport"
        AG_STORAGE_DISK_REMOVABLE["$device"]="$removable"

        # ----------------------------------------------------------------------
        # Classify device
        # ----------------------------------------------------------------------

        case "$transport" in

            usb)
                AG_STORAGE_DISK_CLASS["$device"]="usb"
                AG_STORAGE_USB_DISKS+=("$device")
                ;;

            nvme|sata|ata|sas)
                AG_STORAGE_DISK_CLASS["$device"]="internal"
                AG_STORAGE_INTERNAL_DISKS+=("$device")
                ;;

            *)
                AG_STORAGE_DISK_CLASS["$device"]="other"
                AG_STORAGE_OTHER_DISKS+=("$device")
                ;;

        esac

    done

    msg "Storage classification completed"
}
