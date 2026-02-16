# cutel-cisco-autoprov-scripts

A selection of tcl scripts aimed at making "auto-provisioning" Cisco equipment easier. 

## Notes

* This is aimed as a demo or proof of concept rather than something you want to use in production
* It's assumed you have configs on a web server somewhere. This isn't currently covered in this project, so you will have to draw the rest of the owl.
* The scripts have only been tested on the Cisco VG224 and Cisco VG310s.
* This might be a terrible idea. Running `configure replace` with the wrong config could lock you out of your system.
* There's no support for authentication on the HTTP server at present. I'm going over a private, encrypted network so it's less critical.
* Pulling configs over TFTP / HTTP is inherently insecure. I *might* explore using SCP in future.
* The scripts probably aren't catching all the potential errors very well.

## Bootstrapping

When a Cisco VG[23]XX (and others) boots without a valid startup-config saved in the NVRAM, it will boot with a DHCP client enabled on the 0/0 interface and attempt to pull a config file from a TFTP server, both of which can be specified in the the DHCP options. If the options aren't present, it will instead fall back to trying to connect to a TFTP server running on the default gateway and pull the following files:

* `network-confg`
* `bootstrap-confg`
* `cisconet.cfg`

These can include a basic configuration that pulls down the additional scripts required to auto provision the unit.

See the TFTP folder for examples.


## Provisioning
You'll see `tftp/network-confg` contains an EEM applet that downloads a library of TCL scripts and runs `setup-autoprov.tcl`, which does the following:

### Configures SSH

* If there isn't an SSH key in the running config it will attempt to restore it from the flash.
* If theres no key in the flash, it will generate a new one.
* Once there's a key, it enables SSH version 2

### Downloads a config file from a web server and applies it

I tried a few approaches, however: 

When running `configure replace http://...` for the first time it re-creates the EEM applet, which will stop it from running. This prevents it from doing other tasks like writing to startup-config, or scheduling a reload

If instead we do a `copy http://... running-config` it disrupts the network, recreates (and stops) the EEM applet, and generally causes problems.

To handle this there's two modes:

#### Normal Mode

`tclsh library/setup-autoprov.tcl normal`

This is a "traditional" approach where the configuration is saved to the startup-config.
* Downloads the config to the **startup-config**: `copy http://... startup-config`
* Reloads the device, so it boots from the new startup-config

Assuming we don't have to generate an SSH key, it takes ~6 minutes to boot into a working state, but subsequent boots will take ~3 minutes


#### Stateless Mode
`tclsh library/setup-autoprov.tcl stateless`

This is a "stateless" approach where the configuration only lives in RAM, and is pulled each time the device boots.
* Downloads & _replaces_ the running-config with `configure replace http://` 
* The config is now running so there's nothing else to do

Assuming we don't have to generate an SSH key, it takes ~3 minutes to boot into a working state.

## Usage

* Setup a webserver somewhere
* Place some configs on there, named as $MAC.cfg where MAC is the mac address of your 0/0 interface, normalised to all caps, no dots.
* Replace the vars in `library/autoprov-env.tcl`
* Create a tar file from the library (See `library/build-tar.sh`)
* Put it somewhere on your webserver
* Setup a TFTP server, and use the examples in the `tftp` to populate it. Remember to update the URL to pull the library. P.S the action IDs in BOOTSTRAP-AUTOPROV _must_ remain the same.
* write erase a Cisco VG[23]XX and reload it
* watch the magic happen, hopefully

## Configure Replace Hacks

`configure replace` is a useful command that can overwrite the running configuration from a file/http/tftp etc. It does so by calculating the diff and applying the relevant commands. However it doesn't seem to be possible to call `configure replace` directly from TCL. Chris J Hart has previously blogged about this limitation [here](https://chrisjhart.com/Cisco-TCL-Script-Not-Running-Configure-Replace/).

However you can call it from an EEM applet:

```
event manager applet CONFIG-REPLACE
 event none
 action 10 cli command "enable"
 action 20 cli command "terminal length 0"
 action 30 set _url "$_none_arg1"
 action 40 cli command "configure replace $_url force"
 action 45 set _out "$_cli_result"
 action 46 regexp "([Ee][Rr][Rr][Oo][Rr]|[Tt]he input file is not a valid config file)" "$_out" _m
 action 47 if $_regexp_result eq 1
 action 48  syslog msg "CFG-REPLACE FAILED. Scheduling retry in 5 minutes. Output: $_out"
 action 49  cli command "configure terminal"
 action 50  cli command "event manager applet BOOTSTRAP-AUTOPROV"
 action 51  cli command "event timer watchdog time 300 maxrun 300000"
 action 52  cli command "no action 0.2"
 action 53  cli command "no action 0.3"
 action 54  cli command "end"
 action 55 end
 action 60 syslog msg "CFG-REPLACE output: $_out"
```

Running it looks something like this:

```
router#event manager run CONFIG-REPLACE http://100.100.100.100:8080/autoprov/startup/B838614C2839.cfg 
router#
Feb 14 18:06:15.610: Rollback:Acquired Configuration lock.
router#
Feb 14 18:06:17.758: %HA_EM-6-LOG: CONFIG-REPLACE: CFG-REPLACE output:
Loading http://100.100.100.100:8080/autoprov/startup/B838614C2839.cfg 
Loading http://100.100.100.100:8080/autoprov/startup/B838614C2839.cfg 

Total number of passes: 1
Rollback Done

```

If it fails it will reconfigure BOOTSTRAP-AUTOPROV to re-try every 5 minutes.

## License

This project is licensed under the MIT License