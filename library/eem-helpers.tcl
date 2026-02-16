# Run an EEM applet and return 0 on success, 1 on failure.
# Failure is detected by seeing "Error"anywhere in combined stdout/stderr.
#
# Usage:
#   if {[run_eem_and_check "CONFIG-REPLACE"]} {
#       puts "failed"
#   } else {
#       puts "ok"
#   }
#
proc run_eem_and_check {applet_name} {
    # Best-effort session prep (don’t fail if already enabled / not supported)
    catch {exec "enable"}
    catch {exec "terminal length 0"}

    set out ""
    set err ""

    # Run applet; capture any error text separately
    catch { set out [exec "event manager run $applet_name"] } err

    # Combine for parsing / debugging
    set rc "$out\n$err"

    if {[regexp -nocase {error|the input file is not a valid config file} $rc]} {
        exec "send log ERROR: EEM $applet_name FAILED"
        return 1
    } else {
        exec "send log EEM $applet_name SUCCESS"
        return 0
    }
}

# Disables an EEM applet
proc disable_eem_applet {name} {
    if {[string length $name] == 0} {
        exec "send log ERROR: EEM name to disable must not be empty"
    }

    exec "send log Disabling EEM applet: ${name}"

    set cmds [list \
        "configure terminal"\
        "no event manager applet $name"\
        "end"\
    ]

    foreach c $cmds {
    "send log Executing $c"
        if {[catch {ios_config $c} err]} {
            # include which command failed
            exec "send log ERROR: Disabling EEM applet failed on '$c': $err"
            return 1
        }
    }
    return 0
}

# Creates the CONFIG-REPLACE applet 
proc create_config_replace_applet {} {

    # This is quite a lot of EEM. I previously tried catching the errors in TCL but when the EEM applet
    # exits it takes down TCL with it, so we have to do everything inside the applet.

    catch { ios_config "no event manager applet CONFIG-REPLACE" }

    set cmd "event manager applet CONFIG-REPLACE"
    set cmd_params [list \
        {event none} \
        {action 10  cli command "enable"} \
        {action 20  cli command "terminal length 0"} \
        {action 30  set _url "$_none_arg1"} \
        {action 40  cli command "configure replace $_url force"} \
        {action 45  set _out "$_cli_result"} \
        {action 46  regexp "([Ee][Rr][Rr][Oo][Rr]|[Tt]he input file is not a valid config file)" "$_out" _m} \
        {action 47  if $_regexp_result eq "1"} \
        {action 48   syslog msg "CFG-REPLACE FAILED. Scheduling retry in 5 minutes. Output: $_out"} \
        {action 49   cli command "configure terminal"} \
        {action 50   cli command "event manager applet BOOTSTRAP-AUTOPROV"} \
        {action 51   cli command "event timer watchdog time 300 maxrun 300000"} \
        {action 52   cli command "no action 30"} \
        {action 53   cli command "no action 40"} \
        {action 54   cli command "end"} \
        {action 55  end} \
        {action 60  syslog msg "CFG-REPLACE output: $_out"} \
    ]

    foreach param $cmd_params {
        if {[catch { ios_config $cmd $param } err]} {
            catch { exec "send log FAIL: Failed to create CONFIG-REPLACE applet '$param' : $err" }
            return 1
        }
    }

    return 0
}


