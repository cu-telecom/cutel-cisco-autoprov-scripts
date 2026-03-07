# Downloads the ztp key from TFTP if it doesn't already exist
proc manage_ztp_key {url} {
    set dest "ztp-key"

    if {[string length $url] == 0} {
        exec "send log ERROR: ZTP key download URL must not be empty"
        return 1
    }

    # Check if the ztp key exists
    set out ""
    catch {set out [exec "dir $dest | i Error"]}

    if {![regexp -nocase {Error opening} $out]} {
        exec "send log INFO: We already have a ztp key, skipping download"
        return 0
    }

    # If it doesn't exist, download it
    exec "send log INFO: ztp key not found, downloading from $url"
    set copy_out ""
    if {[catch {set copy_out [exec "copy $url $dest"]} err]} {
        exec "send log ERROR: copy command failed: $err"
        if {[string length $copy_out]} {
            exec "send log COPY OUT: $copy_out"
        }
        return 1
    }

    # Verify the ztp key has successfully downloaded
    set verify ""
    catch {set verify [exec "dir $dest | i Error"]}

    if {![regexp -nocase {Error opening} $verify]} {
        exec "send log INFO: ztp key download successful"
        return 0
    }

    exec "send log ERROR: ztp key still missing after download"
    return 1
}


# Read ztp key and return contents as a clean single string
proc read_ztp_key {} {
    set fh [open "ztp-key" r]
    set data [read $fh]
    close $fh
    return [string trimright $data "\r\n\t "]
}

