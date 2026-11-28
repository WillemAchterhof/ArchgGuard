#!/usr/bin/env bash

# ==============================================================================
# Storage Fingerprinting
# ==============================================================================
# modules/storage_handling/storage_fingerprinting.sh
#
# Captures and stores storage device fingerprints.
#
# Responsibilities:
#   - Capture the identity of a selected storage device
#   - Store USB storage fingerprints in global variables
#   - Persist internal storage fingerprints to the ArchGuard USB
#   - Update existing fingerprints when a new device is selected
#   - Ensure a reliable device identifier is available
#
# Provides:
#   - storage_fingerprinting_usb()
#   - storage_fingerprinting_internal()
#   - storage_fingerprinting()
#
# Populates:
#   - SELECTED_STORAGE_USB_SERIAL
#   - SELECTED_STORAGE_USB_WWN
#   - SELECTED_STORAGE_USB_MODEL
#   - SELECTED_STORAGE_USB_SIZE
#   - SELECTED_STORAGE_USB_TRANSPORT
#   - SELECTED_STORAGE_INTERNAL_SERIAL
#   - SELECTED_STORAGE_INTERNAL_WWN
#   - SELECTED_STORAGE_INTERNAL_MODEL
#   - SELECTED_STORAGE_INTERNAL_SIZE
#   - SELECTED_STORAGE_INTERNAL_TRANSPORT
#
# Dependencies:
#   - lsblk
#   - msg()
#   - warn()
#   - PROJECT_CONFIGURATION_DIR
#
# Constraints:
#   - Definitions only; no source-time side effects.
#   - Does not discover or classify devices.
#   - Does not select storage devices.
#   - Does not modify storage devices.
#   - Does not execute destructive commands.
#   - Does not accept model and size as sufficient proof of identity.
# ==============================================================================


# ==============================================================================
# USB Storage Fingerprinting
# ==============================================================================

storage_fingerprinting_usb() {

    local storage_device="$1"

    storage_fingerprinting "$storage_device" usb
}


# ==============================================================================
# Internal Storage Fingerprinting
# ==============================================================================

storage_fingerprinting_internal() {

    local storage_device="$1"

    storage_fingerprinting "$storage_device" internal
}


# ==============================================================================
# Storage Fingerprinting
# ==============================================================================

storage_fingerprinting() {

    local storage_device="$1"
    local storage_type="$2"

    local device_type
    local serial
    local wwn
    local model
    local size
    local transport

    local fingerprint_file
    local temporary_file


    # --------------------------------------------------------------------------
    # Validate arguments
    # --------------------------------------------------------------------------

    if [[ -z "$storage_device" ]]; then
        warn "No storage device supplied for fingerprinting"
        return 1
    fi

    case "$storage_type" in
        usb|internal)
            ;;
        *)
            warn "Invalid storage fingerprint type: $storage_type"
            return 1
            ;;
    esac


    # --------------------------------------------------------------------------
    # Verify dependencies
    # --------------------------------------------------------------------------

    if ! command -v lsblk >/dev/null 2>&1; then
        warn "Required command not found: lsblk"
        return 1
    fi

    if [[ ! -b "$storage_device" ]]; then
        warn "Storage device does not exist or is not a block device: $storage_device"
        return 1
    fi


    # --------------------------------------------------------------------------
    # Verify device type
    # --------------------------------------------------------------------------

    if ! device_type=$(lsblk -dnro TYPE "$storage_device" 2>/dev/null); then
        warn "Unable to determine storage device type: $storage_device"
        return 1
    fi

    if [[ "$device_type" != "disk" ]]; then
        warn "Selected device is not a whole disk: $storage_device"
        return 1
    fi


    # --------------------------------------------------------------------------
    # Capture device identity
    # --------------------------------------------------------------------------

    if ! serial=$(lsblk -dnro SERIAL "$storage_device" 2>/dev/null); then
        warn "Unable to read storage device serial number: $storage_device"
        return 1
    fi

    if ! wwn=$(lsblk -dnro WWN "$storage_device" 2>/dev/null); then
        warn "Unable to read storage device WWN: $storage_device"
        return 1
    fi

    if ! model=$(lsblk -dnro MODEL "$storage_device" 2>/dev/null); then
        warn "Unable to read storage device model: $storage_device"
        return 1
    fi

    if ! size=$(lsblk -b -dnro SIZE "$storage_device" 2>/dev/null); then
        warn "Unable to read storage device size: $storage_device"
        return 1
    fi

    if ! transport=$(lsblk -dnro TRAN "$storage_device" 2>/dev/null); then
        warn "Unable to read storage device transport: $storage_device"
        return 1
    fi


    # --------------------------------------------------------------------------
    # Verify fingerprint reliability
    # --------------------------------------------------------------------------

    if [[ -z "$serial" && -z "$wwn" ]]; then
        warn "Unable to establish reliable storage device identity: $storage_device"
        warn "Neither a serial number nor a WWN is available"
        return 1
    fi


    # --------------------------------------------------------------------------
    # Store USB fingerprint in runtime variables
    # --------------------------------------------------------------------------

    if [[ "$storage_type" == "usb" ]]; then

        SELECTED_STORAGE_USB_SERIAL="$serial"
        SELECTED_STORAGE_USB_WWN="$wwn"
        SELECTED_STORAGE_USB_MODEL="$model"
        SELECTED_STORAGE_USB_SIZE="$size"
        SELECTED_STORAGE_USB_TRANSPORT="$transport"

        msg "USB storage fingerprint captured: $storage_device"

        return 0
    fi


    # --------------------------------------------------------------------------
    # Persist internal storage fingerprint
    # --------------------------------------------------------------------------

    if [[ -z "${PROJECT_CONFIGURATION_DIR:-}" ]]; then
        warn "PROJECT_CONFIGURATION_DIR is not initialized"
        return 1
    fi

    if [[ ! -d "$PROJECT_CONFIGURATION_DIR" || ! -w "$PROJECT_CONFIGURATION_DIR" ]]; then
        warn "Project configuration directory is missing or not writable"
        return 1
    fi

    fingerprint_file="$PROJECT_CONFIGURATION_DIR/internal_disk.fingerprint"

    # --------------------------------------------------------------------------
    # Create temporary fingerprint file
    # --------------------------------------------------------------------------

    if ! temporary_file=$(mktemp "$PROJECT_CONFIGURATION_DIR/.internal_disk.XXXXXX"); then
        warn "Unable to create temporary fingerprint file"
        return 1
    fi


    # --------------------------------------------------------------------------
    # Write fingerprint
    # --------------------------------------------------------------------------

    if ! chmod 600 "$temporary_file" ||
       ! printf '%s\n' \
            "FORMAT_VERSION=1" \
            "DEVICE_PATH=$storage_device" \
            "DEVICE_SERIAL=$serial" \
            "DEVICE_WWN=$wwn" \
            "DEVICE_MODEL=$model" \
            "DEVICE_SIZE=$size" \
            "DEVICE_TRANSPORT=$transport" \
            > "$temporary_file"; then

        rm -f "$temporary_file"

        warn "Unable to write internal storage fingerprint"
        return 1
    fi


    # --------------------------------------------------------------------------
    # Atomically replace existing fingerprint
    # --------------------------------------------------------------------------

    if ! mv -f "$temporary_file" "$fingerprint_file"; then

        rm -f "$temporary_file"

        warn "Unable to update internal storage fingerprint"
        return 1
    fi


    # --------------------------------------------------------------------------
    # Update runtime variables
    # --------------------------------------------------------------------------

    SELECTED_STORAGE_INTERNAL_SERIAL="$serial"
    SELECTED_STORAGE_INTERNAL_WWN="$wwn"
    SELECTED_STORAGE_INTERNAL_MODEL="$model"
    SELECTED_STORAGE_INTERNAL_SIZE="$size"
    SELECTED_STORAGE_INTERNAL_TRANSPORT="$transport"


    # --------------------------------------------------------------------------
    # Report success
    # --------------------------------------------------------------------------

    msg "Internal storage fingerprint captured: $storage_device"

    return 0
}