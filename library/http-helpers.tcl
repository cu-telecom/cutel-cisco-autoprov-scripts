# Copy helper. Returns 0 on success, 1 on failure
#
# set url "http://100.100.100.100:8080/autoprov/startup/6C2056B08901.cfg"
# set dst "slot0:/6C2056B08901.cfg"
#
# set rc [ios_copy $url $dst]
#
# if {$rc == 0} {
#    puts "SUCCESS"
# } else {
#    puts "FAILURE"
# }

# Detect common IOS failure patterns in CLI output
proc _ios_failed {text} {
    return [regexp -nocase {(^|[\r\n])%.*error|file not found|no such file|unable to open|not[ -]?found|timed out|connection refused} $text]
}

# Copy src -> dst and checks output for failure patterns
proc ios_copy {src dst} {

    set out ""
    set err ""

    # Execute copy
    catch { set out [exec "copy $src $dst"] } err
    set all "$out\n$err"

    # Check output for failure
    if {[_ios_failed $all]} {
        exec "send log ERROR: copy failed: $out"
        return 1
    }

    return 0
}

