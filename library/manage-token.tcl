# This file is currently unused, but included for posterity

# Downloads the token from TFTP if it doesn't already exist
proc manage_token {url} {
    set dest "token"

    if {[string length $url] == 0} {
        exec "send log ERROR: Token download URL must not be empty"
        return 1
    }

    # Check if the token exists
    set out ""
    catch {set out [exec "dir $dest | i Error"]}

    if {![regexp -nocase {Error opening} $out]} {
        return 0
    }

    # If it doesn't exist, download it
    exec "send log INFO: token not found, downloading"
    set copy_out ""
    if {[catch {set copy_out [exec "copy $url $dest"]} err]} {
        exec "send log ERROR: copy command failed: $err"
        if {[string length $copy_out]} {
            exec "send log COPY OUT: $copy_out"
        }
        return 1
    }

    # Verify the token has succesfully downloaded
    set verify ""
    catch {set verify [exec "dir $dest | i Error"]}

    if {![regexp -nocase {Error opening} $verify]} {
        return 0
    }

    exec "send log ERROR: token still missing after download"
    return 1
}


# Read slot0:/token and return contents as a clean single string
proc _read_token {} {
    set fh [open "token" r]
    set data [read $fh]
    close $fh
    return [string trimright $data "\r\n\t "]
}

