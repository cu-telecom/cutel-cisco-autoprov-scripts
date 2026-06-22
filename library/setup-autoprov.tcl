source library/autoprov-env.tcl
source library/var-parsers.tcl
source library/manage-ssh.tcl
source library/manage-router.tcl
source library/manage-scp-pass.tcl
source library/eem-helpers.tcl
source library/http-helpers.tcl

# Get some vars, these vary between VG310 and VG2XX

set model [get_model]
if {$model == ""} {
    exec "send log ERROR: Unable to parse model"
    return 1
}

set path [get_path $model]
if {$path == ""} {
    exec "send log ERROR: Unable to parse path"
    return 1
}

set serial [get_serial]
if {$serial == ""} {
    exec "send log ERROR: Unable to parse serial"
    exit
}

exec "send log model: $model path: $path serial: $serial"

# Manage SSH
manage_ssh

# Manage the SCP password
manage_scp_pass "${scp_password_url}/${serial}"

# Are we using HTTP or SCP to download the config?
if {[string equal -nocase $url_scheme http]} {
    set download_url "http://${http_url_prefix}${serial}.cfg"
} else {
    set scp_user "u[string tolower $serial]"
    set scp_password [read_scp_pass]
    set download_url "scp://${scp_user}:${scp_password}@${scp_url_prefix}${serial}.cfg"
}

exec "send log Mode selected: ${mode}"

# Are we in stateless mode?
if {[string equal -nocase $mode stateless]} {

    create_config_replace_applet

    # Run config-replace 
    exec "send log Running configure-replace"
    set rc [run_eem_and_check "CONFIG-REPLACE ${download_url}"]

    if {$rc != 0} {
        exec "send log ERROR: configure replace failed, reconfiguring BOOTSTRAP-AUTOPROV to retry every 5 minutes"

        create_bootstrap_autoprov_applet
        return

    } else {
        exec "send log configure replace successful"
    }

} else {

    exec "send log Copying the config and reloading"

    # Disable prompting when we copy run start
    ios_config "file prompt quiet"

    # Fetch the startup config using the serial e.g http://autoprov.cutel.net/startup/$serial.cfg
    exec "send log Downloading the startup-config with ${url_scheme} and saving to startup-config"
    set rc [ios_copy ${download_url} startup-config]

    if {$rc != 0} {
        exec "send log ERROR: startup-config download failed."
        exec "send log ERROR: Reconfiguring BOOTSTRAP-AUTOPROV to retry every 5 minutes"

        ios_config "event manager applet BOOTSTRAP-AUTOPROV" "event timer watchdog time 300 maxrun 300000"
        return
    }

    # If we made it this far, we have been successful
    exec "send log Autoprov complete!"

    # Schedule a reload
    schedule_reload 2 "Autoprov complete"

}