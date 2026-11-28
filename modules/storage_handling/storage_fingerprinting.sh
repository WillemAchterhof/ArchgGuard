#!/usr/bin/env bash

# ==============================================================================
# Storage Fingerprinting
# ==============================================================================
# modules/storage_handling/storage_fingerprinting.sh
#
# Captures and stores storage device fingerprints.
#
# Provides:
#   - storage_fingerprinting_usb()
#   - storage_fingerprinting_internal()
#   - storage_fingerprinting()
#
# Dependencies:
#   - lsblk
#   - msg()
#   - warn()
#   - trap_err()
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
# Centralized Unexpected Command Failure
# ==============================================================================

_storage_fingerprinting_command_failure() {

    local exit_code="$1"
    local failing_command="$2"
    local line="$3"
    local caller_line="${BASH_LINENO[0]:-unknown}"

    trap_err "$exit_code" "$failing_command" "$line" "$caller_line"
}


# ==============================================================================
# USB Storage Fingerprinting
# ==============================================================================

storage_fingerprinting_usb() {

    if (( $# != 1 )); then
        warn "storage_fingerprinting_usb requires exactly one device argument"
        return 1
    fi

    storage_fingerprinting "$1" usb
}


# ==============================================================================
# Internal Storage Fingerprinting
# ==============================================================================

storage_fingerprinting_internal() {

    if (( $# != 1 )); then
        warn "storage_fingerprinting_internal requires exactly one device argument"
        return 1
    fi

    storage_fingerprinting "$1" internal
}


# ==============================================================================
# Storage Fingerprinting
# ==============================================================================

storage_fingerprinting() {

    if (( $# != 2 )); then
        warn "storage_fingerprinting requires a device and storage type"
        return 1
    fi

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

    local command_line
    local command_status


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
    # Validate device
    # --------------------------------------------------------------------------

    if [[ ! -b "$storage_device" ]]; then
        warn "Storage device does not exist or is not a block device: $storage_device"
        return 1
    fi


    # --------------------------------------------------------------------------
    # Verify device type
    # --------------------------------------------------------------------------

    command_line=$LINENO

    if device_type=$(lsblk -dnro TYPE "$storage_device" 2>/dev/null); then
        :
    else
        command_status=$?
        _storage_fingerprinting_command_failure \
            "$command_status" \
            "lsblk -dnro TYPE $storage_device" \
            "$command_line"
        return 1
    fi

    if [[ "$device_type" != "disk" ]]; then
        warn "Selected device is not a whole disk: $storage_device"
        return 1
    fi


    # --------------------------------------------------------------------------
    # Capture device identity
    # --------------------------------------------------------------------------

    command_line=$LINENO

    if serial=$(lsblk -dnro SERIAL "$storage_device" 2>/dev/null); then
        :
    else
        command_status=$?
        _storage_fingerprinting_command_failure \
            "$command_status" \
            "lsblk -dnro SERIAL $storage_device" \
            "$command_line"
        return 1
    fi

    command_line=$LINENO

    if wwn=$(lsblk -dnro WWN "$storage_device" 2>/dev/null); then
        :
    else
        command_status=$?
        _storage_fingerprinting_command_failure \
            "$command_status" \
            "lsblk -dnro WWN $storage_device" \
            "$command_line"
        return 1
    fi

    command_line=$LINENO

    if model=$(lsblk -dnro MODEL "$storage_device" 2>/dev/null); then
        :
    else
        command_status=$?
        _storage_fingerprinting_command_failure \
            "$command_status" \
            "lsblk -dnro MODEL $storage_device" \
            "$command_line"
        return 1
    fi

    command_line=$LINENO

    if size=$(lsblk -b -dnro SIZE "$storage_device" 2>/dev/null); then
        :
    else
        command_status=$?
        _storage_fingerprinting_command_failure \
            "$command_status" \
            "lsblk -b -dnro SIZE $storage_device" \
            "$command_line"
        return 1
    fi

    command_line=$LINENO

    if transport=$(lsblk -dnro TRAN "$storage_device" 2>/dev/null); then
        :
    else
        command_status=$?
        _storage_fingerprinting_command_failure \
            "$command_status" \
            "lsblk -dnro TRAN $storage_device" \
            "$command_line"
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
    # Validate configuration directory
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

    command_line=$LINENO

    if temporary_file=$(mktemp "$PROJECT_CONFIGURATION_DIR/.internal_disk.XXXXXX"); then
        :
    else
        command_status=$?
        _storage_fingerprinting_command_failure \
            "$command_status" \
            "mktemp internal storage fingerprint" \
            "$command_line"
        return 1
    fi


    # --------------------------------------------------------------------------
    # Set temporary file permissions
    # --------------------------------------------------------------------------

    command_line=$LINENO

    if chmod 600 "$temporary_file"; then
        :
    else
        command_status=$?
        rm -f "$temporary_file" 2>/dev/null || true

        _storage_fingerprinting_command_failure \
            "$command_status" \
            "chmod 600 $temporary_file" \
            "$command_line"
        return 1
    fi


    # --------------------------------------------------------------------------
    # Write fingerprint
    # --------------------------------------------------------------------------

    command_line=$LINENO

    if printf '%s\n' \
        "FORMAT_VERSION=1" \
        "DEVICE_PATH=$storage_device" \
        "DEVICE_SERIAL=$serial" \
        "DEVICE_WWN=$wwn" \
        "DEVICE_MODEL=$model" \
        "DEVICE_SIZE=$size" \
        "DEVICE_TRANSPORT=$transport" \
        > "$temporary_file"; then
        :
    else
        command_status=$?
        rm -f "$temporary_file" 2>/dev/null || true

        _storage_fingerprinting_command_failure \
            "$command_status" \
            "write internal storage fingerprint" \
            "$command_line"
        return 1
    fi


    # --------------------------------------------------------------------------
    # Atomically replace existing fingerprint
    # --------------------------------------------------------------------------

    command_line=$LINENO

    if mv -f "$temporary_file" "$fingerprint_file"; then
        :
    else
        command_status=$?
        rm -f "$temporary_file" 2>/dev/null || true

        _storage_fingerprinting_command_failure \
            "$command_status" \
            "mv internal storage fingerprint" \
            "$command_line"
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