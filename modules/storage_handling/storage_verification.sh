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
#   - trap_err()
#   - PROJECT_CONFIGURATION_DIR
#
# Constraints:
#   - Does not discover or classify devices.
#   - Does not select storage devices.
#   - Does not modify storage devices.
#   - Does not execute destructive commands.
#   - Fails closed when identity cannot be established.
# ==============================================================================


# ==============================================================================
# Centralized Unexpected Command Failure
# ==============================================================================

_storage_verification_command_failure() {

    local exit_code="$1"
    local failing_command="$2"
    local line="$3"
    local caller_line="${BASH_LINENO[0]:-unknown}"

    trap_err "$exit_code" "$failing_command" "$line" "$caller_line"
}


# ==============================================================================
# Storage Verification
# ==============================================================================

storage_verification() {

    if (( $# != 2 )); then
        warn "storage_verification requires a device and storage type"
        return 1
    fi

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

    local key=""
    local value=""

    local seen_format=0
    local seen_path=0
    local seen_serial=0
    local seen_wwn=0
    local seen_model=0
    local seen_size=0
    local seen_transport=0

    local command_line
    local command_status


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
    # Validate device
    # --------------------------------------------------------------------------

    if [[ ! -b "$storage_device" ]]; then
        warn "Storage device is not a block device: $storage_device"
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
        _storage_verification_command_failure \
            "$command_status" \
            "lsblk -dnro TYPE $storage_device" \
            "$command_line"
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


        # ----------------------------------------------------------------------
        # Parse internal fingerprint
        # ----------------------------------------------------------------------

        while IFS='=' read -r key value || [[ -n "$key" ]]; do

            case "$key" in

                FORMAT_VERSION)
                    if (( seen_format )); then
                        warn "Duplicate FORMAT_VERSION in internal fingerprint"
                        return 1
                    fi
                    seen_format=1
                    format_version="$value"
                    ;;

                DEVICE_PATH)
                    if (( seen_path )); then
                        warn "Duplicate DEVICE_PATH in internal fingerprint"
                        return 1
                    fi
                    seen_path=1
                    ;;

                DEVICE_SERIAL)
                    if (( seen_serial )); then
                        warn "Duplicate DEVICE_SERIAL in internal fingerprint"
                        return 1
                    fi
                    seen_serial=1
                    expected_serial="$value"
                    ;;

                DEVICE_WWN)
                    if (( seen_wwn )); then
                        warn "Duplicate DEVICE_WWN in internal fingerprint"
                        return 1
                    fi
                    seen_wwn=1
                    expected_wwn="$value"
                    ;;

                DEVICE_MODEL)
                    if (( seen_model )); then
                        warn "Duplicate DEVICE_MODEL in internal fingerprint"
                        return 1
                    fi
                    seen_model=1
                    expected_model="$value"
                    ;;

                DEVICE_SIZE)
                    if (( seen_size )); then
                        warn "Duplicate DEVICE_SIZE in internal fingerprint"
                        return 1
                    fi
                    seen_size=1
                    expected_size="$value"
                    ;;

                DEVICE_TRANSPORT)
                    if (( seen_transport )); then
                        warn "Duplicate DEVICE_TRANSPORT in internal fingerprint"
                        return 1
                    fi
                    seen_transport=1
                    ;;

                *)
                    warn "Unexpected field in internal storage fingerprint: $key"
                    return 1
                    ;;

            esac

        done < "$fingerprint_file"


        # ----------------------------------------------------------------------
        # Validate fingerprint structure
        # ----------------------------------------------------------------------

        if (( ! seen_format || ! seen_path || ! seen_serial ||
              ! seen_wwn || ! seen_model || ! seen_size ||
              ! seen_transport )); then

            warn "Internal storage fingerprint is incomplete"
            return 1
        fi

        if [[ "$format_version" != "1" ]]; then
            warn "Unsupported or invalid internal fingerprint format"
            return 1
        fi
    fi


    # --------------------------------------------------------------------------
    # Validate expected identity
    # --------------------------------------------------------------------------

    if [[ -z "$expected_serial" && -z "$expected_wwn" ]]; then
        warn "Stored fingerprint has no reliable device identifier"
        return 1
    fi


    # --------------------------------------------------------------------------
    # Capture actual device identity
    # --------------------------------------------------------------------------

    command_line=$LINENO

    if actual_serial=$(lsblk -dnro SERIAL "$storage_device" 2>/dev/null); then
        :
    else
        command_status=$?
        _storage_verification_command_failure \
            "$command_status" \
            "lsblk -dnro SERIAL $storage_device" \
            "$command_line"
        return 1
    fi

    command_line=$LINENO

    if actual_wwn=$(lsblk -dnro WWN "$storage_device" 2>/dev/null); then
        :
    else
        command_status=$?
        _storage_verification_command_failure \
            "$command_status" \
            "lsblk -dnro WWN $storage_device" \
            "$command_line"
        return 1
    fi

    command_line=$LINENO

    if actual_model=$(lsblk -dnro MODEL "$storage_device" 2>/dev/null); then
        :
    else
        command_status=$?
        _storage_verification_command_failure \
            "$command_status" \
            "lsblk -dnro MODEL $storage_device" \
            "$command_line"
        return 1
    fi

    command_line=$LINENO

    if actual_size=$(lsblk -b -dnro SIZE "$storage_device" 2>/dev/null); then
        :
    else
        command_status=$?
        _storage_verification_command_failure \
            "$command_status" \
            "lsblk -b -dnro SIZE $storage_device" \
            "$command_line"
        return 1
    fi


    # --------------------------------------------------------------------------
    # Compare strong identifiers
    # --------------------------------------------------------------------------

    if [[ -n "$expected_serial" ]]; then

        if [[ -z "$actual_serial" || "$actual_serial" != "$expected_serial" ]]; then
            warn "Storage verification failed: serial number mismatch"
            warn "Expected device identity does not match: $storage_device"
            return 1
        fi

    fi

    if [[ -n "$expected_wwn" ]]; then

        if [[ -z "$actual_wwn" || "$actual_wwn" != "$expected_wwn" ]]; then
            warn "Storage verification failed: WWN mismatch"
            warn "Expected device identity does not match: $storage_device"
            return 1
        fi

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