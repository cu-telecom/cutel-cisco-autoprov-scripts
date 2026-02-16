source library/autoprov-env.tcl
source library/var-parsers.tcl
source library/manage-ssh.tcl
source library/manage-router.tcl
source library/eem-helpers.tcl
source library/http-helpers.tcl
source library/manage-router.tcl

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

set interface [get_interface $model]
if {$interface == ""} {
    exec "send log ERROR: Unable to parse interface"
    return 1
}

set mac [get_mac "${interface}0/0"]
if {$mac == ""} {
    exec "send log ERROR: Unable to parse MAC"
    exit
}

exec "send log model: $model path: $path interface: $interface MAC: $mac"

# Manage SSH
manage_ssh

set mode normal
catch { set mode [lindex $argv 0] }

# Are we in stateless mode?
if {[string equal -nocase $mode stateless]} {

    exec "send log Were in stateless mode, so run configure-replace"

    create_config_replace_applet

    # Run config-replace 

    set rc [run_eem_and_check "CONFIG-REPLACE ${config_url_prefix}${mac}.cfg"]

    if {$rc != 0} {
        exec "send log ERROR: configure replace failed"
        exec "send log ERROR: Reconfiguring BOOTSTRAP-AUTOPROV to retry every 5 minutes"

        ios_config "event manager applet BOOTSTRAP-AUTOPROV" "event timer watchdog time 300 maxrun 300000"

        # Disable downloading the library again to reduce flash wear
        ios_config "event manager applet BOOTSTRAP-AUTOPROV" "no action 0.2"
        ios_config "event manager applet BOOTSTRAP-AUTOPROV" "no action 0.3"

        return
    }

} else {

    exec "send log We're in normal mode, so copy the config and reload"

    # Disable prompting when we copy run start
    ios_config "file prompt quiet"

    # Fetch the startup config using the MAC e.g http://autoprov.cutel.net/startup/$mac.cfg
    exec "send log Downloading the startup-config from ${config_url_prefix}${mac}.cfg and saving to startup-config"
    set rc [ios_copy ${config_url_prefix}${mac}.cfg startup-config]

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