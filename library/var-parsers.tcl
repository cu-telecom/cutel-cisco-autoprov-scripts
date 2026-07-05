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

    if {$model == "VG310" || $model == "VG204" || $model == "VG202"} {
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

# Extracts the chassis serial number from show inventory
proc get_serial {} {
    if {[catch {exec "show inventory"} output]} {
        return ""
    }
    if {[regexp {SN: (\S+)} $output -> serial]} {
        return [string toupper $serial]
    }
    return ""
}