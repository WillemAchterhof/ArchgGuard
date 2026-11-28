#!/usr/bin/env bash

# ==============================================================================
# Storage Verification
# ==============================================================================
# modules/storage_handling/storage_verification.sh
#
# Verifies that a storage device matches its previously captured fingerprint.
#
# Provides:
#   - storage_verification()
#
# Usage:
#   storage_verification "/dev/sda" usb
#   storage_verification "/dev/nvme0n1" internal
#
# Return values:
#   0 - Device identity verified
#   1 - Verification failed
#
# Dependencies:
#   - lsblk
#   - warn()
#   - msg()
#   - PROJECT_CONFIGURATION_DIR
#
# Constraints:
#   - Does not discover or classify devices.
#   - Does not select storage devices.
#   - Does not modify storage devices.
#   - Does not execute destructive commands.
#   - Fails closed when identity cannot be established.
# ==============================================================================

storage_verification() {

    local storage_device="$1"
    local storage_type="$2"

    local device_type
    local actual_serial
    local actual_wwn
    local actual_model
    local actual_size

    local expected_serial=""
    local expected_wwn=""
    local expected_model=""
    local expected_size=""

    local fingerprint_file
    local format_version=""
    local key
    local value
    local identity_available=0


    # --------------------------------------------------------------------------
    # Validate arguments
    # --------------------------------------------------------------------------

    if [[ -z "$storage_device" ]]; then
        warn "No storage device supplied for verification"
        return 1
    fi

    case "$storage_type" in
        usb|internal)
            ;;
        *)
            warn "Invalid storage verification type: $storage_type"
            return 1
            ;;
    esac


    # --------------------------------------------------------------------------
    # Verify dependencies and device
    # --------------------------------------------------------------------------

    if ! command -v lsblk >/dev/null 2>&1; then
        warn "Required command not found: lsblk"
        return 1
    fi

    if [[ ! -b "$storage_device" ]]; then
        warn "Storage device is not a block device: $storage_device"
        return 1
    fi

    if ! device_type=$(lsblk -dnro TYPE "$storage_device" 2>/dev/null); then
        warn "Unable to determine storage device type: $storage_device"
        return 1
    fi

    if [[ "$device_type" != "disk" ]]; then
        warn "Verification target is not a whole disk: $storage_device"
        return 1
    fi


    # --------------------------------------------------------------------------
    # Load expected fingerprint
    # --------------------------------------------------------------------------

    if [[ "$storage_type" == "usb" ]]; then

        expected_serial="${SELECTED_STORAGE_USB_SERIAL:-}"
        expected_wwn="${SELECTED_STORAGE_USB_WWN:-}"
        expected_model="${SELECTED_STORAGE_USB_MODEL:-}"
        expected_size="${SELECTED_STORAGE_USB_SIZE:-}"

    else

        if [[ -z "${PROJECT_CONFIGURATION_DIR:-}" ]]; then
            warn "PROJECT_CONFIGURATION_DIR is not initialized"
            return 1
        fi

        fingerprint_file="$PROJECT_CONFIGURATION_DIR/internal_disk.fingerprint"

        if [[ ! -f "$fingerprint_file" || ! -r "$fingerprint_file" ]]; then
            warn "Internal storage fingerprint is missing or unreadable"
            return 1
        fi

        while IFS='=' read -r key value || [[ -n "$key" ]]; do
            case "$key" in
                FORMAT_VERSION)
                    format_version="$value"
                    ;;
                DEVICE_SERIAL)
                    expected_serial="$value"
                    ;;
                DEVICE_WWN)
                    expected_wwn="$value"
                    ;;
                DEVICE_MODEL)
                    expected_model="$value"
                    ;;
                DEVICE_SIZE)
                    expected_size="$value"
                    ;;
                DEVICE_PATH|DEVICE_TRANSPORT)
                    # Informational fields; not used as identity proof.
                    ;;
                *)
                    warn "Unexpected field in internal storage fingerprint: $key"
                    return 1
                    ;;
            esac
        done < "$fingerprint_file"

        if [[ "$format_version" != "1" ]]; then
            warn "Unsupported or invalid internal fingerprint format"
            return 1
        fi
    fi


    # --------------------------------------------------------------------------
    # Validate expected fingerprint
    # --------------------------------------------------------------------------

    if [[ -z "$expected_serial" && -z "$expected_wwn" ]]; then
        warn "Stored fingerprint has no reliable device identifier"
        return 1
    fi


    # --------------------------------------------------------------------------
    # Capture actual device identity
    # --------------------------------------------------------------------------

    if ! actual_serial=$(lsblk -dnro SERIAL "$storage_device" 2>/dev/null); then
        warn "Unable to read device serial number: $storage_device"
        return 1
    fi

    if ! actual_wwn=$(lsblk -dnro WWN "$storage_device" 2>/dev/null); then
        warn "Unable to read device WWN: $storage_device"
        return 1
    fi

    if ! actual_model=$(lsblk -dnro MODEL "$storage_device" 2>/dev/null); then
        warn "Unable to read device model: $storage_device"
        return 1
    fi

    if ! actual_size=$(lsblk -b -dnro SIZE "$storage_device" 2>/dev/null); then
        warn "Unable to read device size: $storage_device"
        return 1
    fi


    # --------------------------------------------------------------------------
    # Compare strong identifiers
    # --------------------------------------------------------------------------

    if [[ -n "$expected_serial" ]]; then
        identity_available=1

        if [[ -z "$actual_serial" || "$actual_serial" != "$expected_serial" ]]; then
            warn "Storage verification failed: serial number mismatch"
            warn "Expected device identity does not match: $storage_device"
            return 1
        fi
    fi

    if [[ -n "$expected_wwn" ]]; then
        identity_available=1

        if [[ -z "$actual_wwn" || "$actual_wwn" != "$expected_wwn" ]]; then
            warn "Storage verification failed: WWN mismatch"
            warn "Expected device identity does not match: $storage_device"
            return 1
        fi
    fi

    if (( identity_available == 0 )); then
        warn "Storage verification failed: no strong identifier available"
        return 1
    fi


    # --------------------------------------------------------------------------
    # Compare consistency fields
    # --------------------------------------------------------------------------

    if [[ -n "$expected_model" && "$actual_model" != "$expected_model" ]]; then
        warn "Storage verification failed: model mismatch"
        return 1
    fi

    if [[ -n "$expected_size" && "$actual_size" != "$expected_size" ]]; then
        warn "Storage verification failed: size mismatch"
        return 1
    fi


    # --------------------------------------------------------------------------
    # Report success
    # --------------------------------------------------------------------------

    msg "Storage device identity verified: $storage_device"

    return 0
}