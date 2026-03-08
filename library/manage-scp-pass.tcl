# Downloads the scp password from TFTP if it doesn't already exist
proc manage_scp_pass {url} {
    set dest "nvram:/scp-pass"

    if {[string length $url] == 0} {
        exec "send log ERROR: scp password download URL must not be empty"
        return 1
    }

    # Check if the scp password exists
    set out ""
    catch {set out [exec "dir $dest | i Error"]}

    if {![regexp -nocase {Error opening} $out]} {
        exec "send log INFO: We already have a scp password, skipping download"
        return 0
    }

    # If it doesn't exist, download it
    exec "send log INFO: scp password not found, downloading from $url"
    set copy_out ""
    if {[catch {set copy_out [exec "copy $url $dest"]} err]} {
        exec "send log ERROR: copy command failed: $err"
        if {[string length $copy_out]} {
            exec "send log COPY OUT: $copy_out"
        }
        return 1
    }

    # Verify the scp password has successfully downloaded
    set verify ""
    catch {set verify [exec "dir $dest | i Error"]}

    if {![regexp -nocase {Error opening} $verify]} {
        exec "send log INFO: scp password download successful"
        return 0
    }

    exec "send log ERROR: scp password still missing after download"
    return 1
}


# Read scp password and return contents as a clean single string
proc read_scp_pass {} {
    set fh [open "nvram:/scp-pass" r]
    set data [read $fh]
    close $fh
    return [string trimright $data "\r\n\t "]
}

