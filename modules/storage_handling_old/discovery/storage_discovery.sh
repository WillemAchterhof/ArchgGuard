
#!/usr/bin/env bash

# ==============================================================================
# Storage Device Discovery
# ==============================================================================
# modules/storage_handling/discovery/storage_discovery.sh
#
# Discovers available storage devices.
#
# Responsibilities:
#   - Discover available disk devices
#   - Exclude partitions and non-disk devices
#   - Store discovered devices in a global array
#   - Maintain the discovered device count
#
# Provides:
#   - storage_discover_disks()
#
# Populates:
#   - AG_STORAGE_DISKS
#   - AG_STORAGE_DISK_COUNT
#
# Dependencies:
#   - lsblk
#   - msg()
#   - warn()
#
# Constraints:
#   - Definitions only; no source-time side effects.
#   - Discovery is read-only.
#   - Does not classify devices.
#   - Does not display selection menus.
#   - Does not select or modify devices.
# ==============================================================================

# ==============================================================================
# Discover Storage Devices
# ==============================================================================

storage_discover_disks() {
    local lsblk_output
    local device
    local type

    declare -g -a AG_STORAGE_DISKS=()
    declare -g -i AG_STORAGE_DISK_COUNT=0

    # --------------------------------------------------------------------------
    # Verify dependency
    # --------------------------------------------------------------------------

    if ! command -v lsblk >/dev/null 2>&1; then
        fatal "Required command not found: lsblk"
        return 1
    fi

    # --------------------------------------------------------------------------
    # Discover disk devices
    # --------------------------------------------------------------------------

    if ! lsblk_output=$(lsblk -dnpo NAME,TYPE 2>/dev/null); then
        warn "Unable to discover storage devices"
        return 1
    fi

    while read -r device type; do

        [[ "$type" == "disk" ]] || continue
        [[ -b "$device" ]] || continue

        AG_STORAGE_DISKS+=("$device")

    done <<< "$lsblk_output"

    # --------------------------------------------------------------------------
    # Update inventory count
    # --------------------------------------------------------------------------

    AG_STORAGE_DISK_COUNT="${#AG_STORAGE_DISKS[@]}"

    if (( AG_STORAGE_DISK_COUNT == 0 )); then
        warn "No storage devices detected"
        return 0
    fi

    msg "Discovered storage devices: $AG_STORAGE_DISK_COUNT"
}
