source library/var-parsers.tcl

# Internal function for checking if we have a config line
proc _has_line {text line} {
    set norm [string map [list "\r" ""] $text]
    return [expr {[regexp -line -- "^${line}\$" $norm] ? 1 : 0}]
}

# Internal function for checking if we have missing SSH config lines
# returns a list of commands to add
proc _get_missing_ssh_cfg {} {

    set cfg_cmds {}

    set out [exec "show run | sec ip ssh"]

    set l1 "ip ssh rsa keypair-name ssh"
    set l2 "ip ssh version 2"

    if {![_has_line $out $l1]} { lappend cfg_cmds $l1 }
    if {![_has_line $out $l2]} { lappend cfg_cmds $l2 }

    return $cfg_cmds
}

# Manages SSH. If no RSA key is in the running-config, attempt to import it from flash.
# If there's no backup available, it will generate a new one. It will enable SSH version 2
proc manage_ssh {} {

    set model [get_model]
    set path [get_path $model]

    set import_file ${path}id_rsa-sign
    set export_file ${path}id_rsa
    set password    password
    set modulus     2048

    set missing_ssh_cmds [_get_missing_ssh_cfg]

    # Check if we already have an RSA key
    set key_out ""
    if {[catch {set key_out [exec "show crypto key mypubkey rsa | include Key name:"]} err]} {
        set key_out ""
    }

    if {[regexp {Key name:} $key_out]} {
        exec "send log SSH key is already in the keychain"

        set cfg_cmds [list \
            "crypto key import rsa ssh url $import_file $password" \
        ]

        # Append any missing commands
        set cfg_cmds [concat $cfg_cmds $missing_ssh_cmds]

        foreach c $cfg_cmds {
            if {[catch {ios_config $c} err]} {
                exec "send log FAIL: Restoring key from backup failed on '$c' : $err"
                return 1
            }
        }

        return 0
    } else {
        exec "send log SSH key is NOT in the keychain"
    }

    # Try to import from a backup
    set out ""
    catch {set out [exec "dir $import_file.prv | i Error"]}

    if {![regexp -nocase {Error opening} $out]} {
        exec "send log Restoring key from backup $import_file"

        set cfg_cmds [list \
            "crypto key import rsa ssh url $import_file $password" \
        ]

        # Append any missing commands
        set cfg_cmds [concat $cfg_cmds $missing_ssh_cmds]

        foreach c $cfg_cmds {
            if {[catch {ios_config $c} err]} {
                exec "send log FAIL: Restoring key from backup failed on '$c' : $err"
                return 1
            }
        }

        exec "send log Enabled SSH v2"
        return 0
    }

    exec "send log No backup key found, generating a new one. This might take a while..."

    # If there's no backup, generate a new one and export it.
    set cfg_cmds [list \
        "crypto key generate rsa exportable usage-keys modulus $modulus label ssh" \
        "crypto key export rsa ssh pem url $export_file 3des $password" \
    ]

    # Append any missing commands
    set cfg_cmds [concat $cfg_cmds $missing_ssh_cmds]

    foreach c $cfg_cmds {
        if {[catch {ios_config $c} err]} {
            exec "send log FAIL: key generation failed on '$c' : $err"
            return 1
        }
    }

    exec "send log Enabled SSH v2"

    catch {ios_config "no event manager environment BOOT-SSH"}

    return 0
}

# --- entrypoint ---
# If the script is being executed (tclsh slot0:/file.tcl), run manage_ssh.
# If it's being sourced, do nothing beyond defining procs.

if {[info exists argv0] && [string equal [info script] $argv0]} {
    manage_ssh
    return
}
