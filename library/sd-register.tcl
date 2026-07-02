source "tmpsys:lib/tcl/http.tcl"
source library/autoprov-env.tcl
source library/var-parsers.tcl

# Extracts the "Internet address" IP from `show ip interface <iface>` output
proc _get_interface_ip {iface} {
    if {[catch {exec "show ip interface $iface | include Internet address"} out]} {
        return ""
    }

    if {[regexp {Internet address is ([0-9.]+)} $out -> ip]} {
        return $ip
    }

    return ""
}

# Return the IP address of the primary interface. Tries BVI1 first (bridged
# devices), falling back to Fa0/0 or Gi0/0 (model dependent)
proc get_primary_ip {} {
    set ip [_get_interface_ip "BVI1"]
    if {$ip != ""} {
        return $ip
    }

    set model [get_model]
    set iface "[get_interface $model]0/0"

    return [_get_interface_ip $iface]
}

# Return the configured hostname
proc get_hostname {} {
    if {[catch {exec "show running-config | include ^hostname"} out]} {
        return ""
    }

    if {[regexp {^hostname\s+(\S+)} $out -> name]} {
        return $name
    }

    return ""
}

# Registers this device with the service discovery endpoint
proc sd_register {} {
    global sd_url_prefix
    global sd_key

    set ip [get_primary_ip]
    if {$ip == ""} {
        exec "send log ERROR: SD-REGISTER unable to determine primary IP address"
        return 1
    }

    set hostname [get_hostname]
    set device_type [string tolower [get_model]]

    set url "http://${sd_url_prefix}/register/${sd_key}?target=${ip}"
    if {$hostname != ""} {
        append url "&label.hostname=${hostname}"
    }
    if {$device_type != ""} {
        append url "&label.device_type=${device_type}"
    }

    if {[catch {set token [::http::geturl $url]} err]} {
        exec "send log ERROR: SD-REGISTER request failed: $err"
        return 1
    }

    set status [::http::status $token]
    set code [::http::ncode $token]
    ::http::cleanup $token

    if {$status != "ok" || $code != 200} {
        exec "send log ERROR: SD-REGISTER failed, status: $status code: $code"
        return 1
    }

    exec "send log SD-REGISTER successful for $hostname ($ip)"
    return 0
}

# --- entrypoint ---
# If the script is being executed (tclsh slot0:/file.tcl), run sd_register.
# If it's being sourced, do nothing beyond defining procs.

if {[info exists argv0] && [string equal [info script] $argv0]} {
    sd_register
    return
}
