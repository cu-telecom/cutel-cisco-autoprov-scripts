# Schedule a reload in X minutes
proc schedule_reload {delay err_msg} {

    # Basic validation
    if {![string is integer -strict $delay] || $delay < 0} {
        exec "send log Invalid reload delay: $delay"
        return 1
    }

    exec "send log Scheduling reload in $delay minute(s): $err_msg"

    if {[catch {exec "reload in $delay"} reload_err]} {
        exec "send log Failed to schedule reload: $reload_err"
        return 1
    }

    return 0
}

# Copies the running config to the startup-config
# Forces file prompt quiet first to avoid having to enter yes
proc write_config {} {

    exec "send log copy running-config startup-config"
    ios_config "file prompt quiet"
    exec "copy running-config startup-config"
    ios_config "no file prompt quiet"

}