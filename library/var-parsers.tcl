# Return the model from the inventory
proc get_model {} {

    if {[catch {exec "show inventory"} output]} {
        return ""
    }

    if {[regexp {NAME: \"([^\"]+)\"} $output -> name]} {

        # Remove trailing " chassis" if present
        regsub -nocase { chassis$} $name "" model

        return $model
    }

    return ""
}

# Return the path i.e slot0 or flash0 based on the model
proc get_path {model} {

    # Normalise input (trim + uppercase just in case)
    set model [string toupper [string trim $model]]

    if {$model == "VG310"} {
        return "flash0:/"
    } else {
        return "slot0:/"
    }
}

# Return the interface type based on the model
proc get_interface {model} {

    # Normalise input (trim + uppercase just in case)
    set model [string toupper [string trim $model]]

    if {$model == "VG310"} {
        return "GigabitEthernet"
    } else {
        return "FastEthernet"
    }
}

# Extracts the BIA MAC address for the supplied interface
proc get_mac {ifc} {
    set out [exec show interfaces $ifc | include bia]
    set pat {([0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f]\.[0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f]\.[0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f])}
    if {[regexp $pat $out -> mac]} {
        set mac [string map { . "" } $mac]
        set mac [string toupper $mac]
        return $mac
    }
    return ""
}