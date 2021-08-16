#!/usr/bin/env wish
################################################################################
# Network Utility                                                              #
#                                                                              #
# Copyright (C) 2021 J.C. Fields (jcfields@jcfields.dev).                      #
#                                                                              #
# Permission is hereby granted, free of charge, to any person obtaining a copy #
# of this software and associated documentation files (the "Software"), to     #
# deal in the Software without restriction, including without limitation the   #
# rights to use, copy, modify, merge, publish, distribute, sublicense, and/or  #
# sell copies of the Software, and to permit persons to whom the Software is   #
# furnished to do so, subject to the following conditions:                     #
#                                                                              #
# The above copyright notice and this permission notice shall be included in   #
# all copies or substantial portions of the Software.                          #
#                                                                              #
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR   #
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,     #
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE  #
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER       #
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING      #
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS #
# IN THE SOFTWARE.                                                             #
################################################################################

package require http

# window size
set default_width 700
set default_height 400

# web site for checking remote IP address
set ip_site http://checkip.amazonaws.com/

################################################################################
# Create main window functions                                                 #
################################################################################

proc make_window {width height} {
	# centers window
	set x [expr {([winfo vrootwidth .] - $width) / 2}]
	set y [expr {([winfo vrootheight .] - $height) / 2}]

	wm title . {Network Utility}
	wm geometry . ${width}x${height}+${x}+${y}
}

proc make_widgets {} {
	ttk::frame .fr
	pack .fr -fill both -expand yes

	add_notebook
	add_output_textarea

	bind . <Return> {start_execution}
	bind . <Escape> {stop_execution}
}

proc add_output_textarea {} {
	ttk::frame .fr.output
	pack .fr.output -fill both -expand yes -padx 5 -pady 5

	ttk::button .fr.output.stop -text Stop -command {stop_execution} \
		-state disabled -takefocus 0
	ttk::button .fr.output.clear -text Clear -command {clear_output} \
		-state disabled -takefocus 0

	text .fr.output.tb -yscrollcommand {.fr.output.sb set}
	ttk::scrollbar .fr.output.sb -orient v -command {.fr.output.tb yview}

	grid .fr.output.tb -row 0 -column 0 -columnspan 2 -sticky news
	grid .fr.output.sb -row 0 -column 2 -sticky news
	grid .fr.output.stop -row 1 -column 0 -pady 5 -sticky w
	grid .fr.output.clear -row 1 -column 1 -columnspan 2 -pady 5 -sticky e

	grid rowconfigure .fr.output 0 -weight 1
	grid columnconfigure .fr.output 0 -weight 1
}

proc add_notebook {} {
	ttk::notebook .fr.nb
	ttk::notebook::enableTraversal .fr.nb
	pack .fr.nb -fill both -expand yes -padx 5 -pady 5

	add_info_tab
	add_netstat_tab
	add_ping_tab
	add_lookup_tab
	add_tracert_tab
	add_whois_tab
	add_finger_tab
	add_nmap_tab
}

proc add_info_tab {} {
	ttk::frame .fr.nb.info
	.fr.nb add .fr.nb.info -text Info

	if [catch {set local [get_local_ip]}] {
		set local —
	}

	if [catch {set remote [get_remote_ip]}] {
		set remote —
	}

	ttk::frame .fr.nb.info.ip
	ttk::label .fr.nb.info.ip.local_label -text {Local IP address: }
	ttk::label .fr.nb.info.ip.local_ip -text $local
	ttk::label .fr.nb.info.ip.remote_label -text {Remote IP address: }
	ttk::label .fr.nb.info.ip.remote_ip -text $remote

	pack .fr.nb.info.ip -expand yes -padx 5 -pady 5
	grid .fr.nb.info.ip.local_label -row 0 -column 0 -sticky ne
	grid .fr.nb.info.ip.local_ip -row 0 -column 1 -sticky nw
	grid .fr.nb.info.ip.remote_label -row 1 -column 0 -sticky ne
	grid .fr.nb.info.ip.remote_ip -row 1 -column 1 -sticky nw

	ttk::frame .fr.nb.info.host
	ttk::button .fr.nb.info.host.submit -text Ifconfig -command {
		run_command ifconfig {}
	} -takefocus 0

	pack .fr.nb.info.host -anchor e -padx 5 -pady 5
	pack .fr.nb.info.host.submit -padx 5 -pady 5
}

proc add_netstat_tab {} {
	ttk::frame .fr.nb.netstat
	.fr.nb add .fr.nb.netstat -text Netstat

	ttk::frame .fr.nb.netstat.opt
	ttk::radiobutton .fr.nb.netstat.opt.r \
		-text {Display routing table information} \
		-variable netstat -value r
	ttk::radiobutton .fr.nb.netstat.opt.s \
		-text {Display network statistics for each protocol} \
		-variable netstat -value s
	ttk::radiobutton .fr.nb.netstat.opt.g \
		-text {Display multicast information} \
		-variable netstat -value g
	ttk::radiobutton .fr.nb.netstat.opt.a \
		-text {Display state of all current socket connections} \
		-variable netstat -value a
	.fr.nb.netstat.opt.a invoke

	pack .fr.nb.netstat.opt -expand yes -padx 5 -pady 5
	grid .fr.nb.netstat.opt.r -row 0 -column 0 -sticky w
	grid .fr.nb.netstat.opt.s -row 1 -column 0 -sticky w
	grid .fr.nb.netstat.opt.g -row 0 -column 1 -sticky w
	grid .fr.nb.netstat.opt.a -row 1 -column 1 -sticky w

	ttk::frame .fr.nb.netstat.host
	ttk::button .fr.nb.netstat.host.submit -text Netstat -command {
		set params {}

		if {$netstat eq {r}} {
			lappend params {-r}
		} elseif {$netstat eq {s}} {
			lappend params {-s}
		} elseif {$netstat eq {g}} {
			lappend params {-g}
		}

		run_command netstat $params
	} -takefocus 0

	pack .fr.nb.netstat.host -anchor e -padx 5 -pady 5
	pack .fr.nb.netstat.host.submit -padx 5 -pady 5
}

proc add_ping_tab {} {
	ttk::frame .fr.nb.ping
	.fr.nb add .fr.nb.ping -text Ping

	ttk::frame .fr.nb.ping.host
	ttk::entry .fr.nb.ping.host.host -width 30
	bind .fr.nb.ping.host.host <KeyRelease> {toggle_submit}
	ttk::button .fr.nb.ping.host.submit -text Ping -command {
		set count [.fr.nb.ping.opt.count get]
		set params {}

		if {$count > 0} {
			lappend params "-c $count"
		}

		lappend params [.fr.nb.ping.host.host get]

		run_command ping $params
	} -state disabled -takefocus 0

	pack .fr.nb.ping.host -expand yes -padx 5 -pady 5
	pack [ttk::label .fr.nb.ping.host.label -text {IP or Host: }] -side left
	pack .fr.nb.ping.host.host -side left
	pack .fr.nb.ping.host.submit -side left -padx 5 -pady 5

	ttk::frame .fr.nb.ping.opt
	ttk::entry .fr.nb.ping.opt.count -width 3 -validate key -validatecommand {
		expr {[string is int %P] && [string length %P] < 3}
	}
	.fr.nb.ping.opt.count insert end 0

	pack .fr.nb.ping.opt -fill both -expand yes -padx 5 -pady 5
	pack [ttk::label .fr.nb.ping.opt.label1 -text {Send }] -side left
	pack .fr.nb.ping.opt.count -side left
	pack [ttk::label .fr.nb.ping.opt.label2 -text {pings (0 for unlimited).}] \
		-side left
}

proc add_lookup_tab {} {
	ttk::frame .fr.nb.lookup
	.fr.nb add .fr.nb.lookup -text Lookup

	ttk::frame .fr.nb.lookup.host
	ttk::entry .fr.nb.lookup.host.host -width 30
	bind .fr.nb.lookup.host.host <KeyRelease> {toggle_submit}
	ttk::button .fr.nb.lookup.host.submit -text Lookup -command {
		set params {}
		lappend params [.fr.nb.lookup.host.host get]

		run_command $lookup $params
	} -state disabled -takefocus 0

	pack .fr.nb.lookup.host -expand yes -padx 5 -pady 5
	pack [ttk::label .fr.nb.lookup.host.label -text {IP or Host: }] -side left
	pack .fr.nb.lookup.host.host -side left
	pack .fr.nb.lookup.host.submit -side left -padx 5 -pady 5

	ttk::frame .fr.nb.lookup.opt
	ttk::radiobutton .fr.nb.lookup.opt.dig -text dig \
		-variable lookup -value dig
	ttk::radiobutton .fr.nb.lookup.opt.host -text host \
		-variable lookup -value host
	ttk::radiobutton .fr.nb.lookup.opt.nslookup -text nslookup \
		-variable lookup -value nslookup
	.fr.nb.lookup.opt.nslookup invoke

	pack .fr.nb.lookup.opt -fill both -expand yes -padx 5 -pady 5
	pack [ttk::label .fr.nb.lookup.opt.label -text {Command: }] -side left
	pack .fr.nb.lookup.opt.dig -side left
	pack .fr.nb.lookup.opt.host -side left
	pack .fr.nb.lookup.opt.nslookup -side left
}

proc add_tracert_tab {} {
	ttk::frame .fr.nb.tracert
	.fr.nb add .fr.nb.tracert -text Traceroute

	ttk::frame .fr.nb.tracert.host
	ttk::entry .fr.nb.tracert.host.host -width 30
	bind .fr.nb.tracert.host.host <KeyRelease> {toggle_submit}
	ttk::button .fr.nb.tracert.host.submit -text Trace -command {
		set time [.fr.nb.tracert.opt.time get]
		set params {}

		if {$time > 0} {
			lappend params "-w $time"
		}

		lappend params [.fr.nb.tracert.host.host get]

		run_command traceroute $params
	} -state disabled -takefocus 0

	pack .fr.nb.tracert.host -expand yes -padx 5 -pady 5
	pack [ttk::label .fr.nb.tracert.host.label -text {IP or Host: }] -side left
	pack .fr.nb.tracert.host.host -side left
	pack .fr.nb.tracert.host.submit -side left -padx 5 -pady 5

	ttk::frame .fr.nb.tracert.opt
	ttk::entry .fr.nb.tracert.opt.time -width 3 -validate key -validatecommand {
		expr {[string is int %P] && [string length %P] < 3}
	}
	.fr.nb.tracert.opt.time insert end 5

	pack .fr.nb.tracert.opt -fill both -expand yes -padx 5 -pady 5
	pack [ttk::label .fr.nb.tracert.opt.label1 -text {Wait up to }] -side left
	pack .fr.nb.tracert.opt.time -side left
	pack [ttk::label .fr.nb.tracert.opt.label2 -text {seconds for response.}] \
		-side left
}

proc add_whois_tab {} {
	ttk::frame .fr.nb.whois
	.fr.nb add .fr.nb.whois -text Whois

	ttk::frame .fr.nb.whois.host
	ttk::entry .fr.nb.whois.host.host -width 30
	bind .fr.nb.whois.host.host <KeyRelease> {toggle_submit}
	ttk::button .fr.nb.whois.host.submit -text Whois -command {
		set params {}
		lappend params [.fr.nb.whois.host.host get]

		set server [.fr.nb.whois.opt.server get]
		lappend params "-h $server"

		run_command whois $params
	} -state disabled -takefocus 0

	pack .fr.nb.whois.host -expand yes -padx 5 -pady 5
	pack [ttk::label .fr.nb.whois.host.label -text {Host: }] -side left
	pack .fr.nb.whois.host.host -side left
	pack .fr.nb.whois.host.submit -side left -padx 5 -pady 5

	ttk::frame .fr.nb.whois.opt
	ttk::combobox .fr.nb.whois.opt.server -width 25 -values \
		[list whois.internic.net whois.networksolutions.com whois.arin.net \
		whois.nic.mil whois.ripe.net]
	.fr.nb.whois.opt.server current 0

	pack .fr.nb.whois.opt -fill both -expand yes -padx 5 -pady 5
	pack [ttk::label .fr.nb.whois.opt.label -text {Whois server: }] -side left
	pack .fr.nb.whois.opt.server -side left
}

proc add_finger_tab {} {
	ttk::frame .fr.nb.finger
	.fr.nb add .fr.nb.finger -text Finger

	ttk::frame .fr.nb.finger.host
	ttk::entry .fr.nb.finger.host.user -width 15
	ttk::entry .fr.nb.finger.host.host -width 25
	bind .fr.nb.finger.host.host <KeyRelease> {toggle_submit}
	ttk::button .fr.nb.finger.host.submit -text Finger -command {
		set params {}
		lappend params [.fr.nb.finger.host.user get]
		lappend params [.fr.nb.finger.host.host get]

		run_command finger $params
	} -state disabled -takefocus 0

	pack .fr.nb.finger.host -expand yes -padx 5 -pady 5
	pack [ttk::label .fr.nb.finger.host.label1 -text {User name: }] -side left
	pack .fr.nb.finger.host.user -side left
	pack [ttk::label .fr.nb.finger.host.label2 -text {IP or Host: }] -side left
	pack .fr.nb.finger.host.host -side left
	pack .fr.nb.finger.host.submit -side left -padx 5 -pady 5
}

proc add_nmap_tab {} {
	ttk::frame .fr.nb.nmap
	.fr.nb add .fr.nb.nmap -text {Port Scan}

	ttk::frame .fr.nb.nmap.host
	ttk::entry .fr.nb.nmap.host.host -width 30
	bind .fr.nb.nmap.host.host <KeyRelease> {toggle_submit}
	ttk::button .fr.nb.nmap.host.submit -text Scan -command {
		set params {}

		if $range {
			set low [.fr.nb.nmap.opt.low get]
			set high [.fr.nb.nmap.opt.high get]
			lappend params "-p $low-$high"
		}

		lappend params [.fr.nb.nmap.host.host get]

		run_command nmap $params
	} -state disabled -takefocus 0

	pack .fr.nb.nmap.host -expand yes -padx 5 -pady 5
	pack [ttk::label .fr.nb.nmap.host.label -text {IP or Host: }] -side left
	pack .fr.nb.nmap.host.host -side left
	pack .fr.nb.nmap.host.submit -side left -padx 5 -pady 5

	ttk::frame .fr.nb.nmap.opt
	ttk::checkbutton .fr.nb.nmap.opt.range -text {Test ports between } \
		-variable range
	.fr.nb.nmap.opt.range invoke
	ttk::entry .fr.nb.nmap.opt.low -width 6 -validate key -validatecommand {
		expr {[string is int %P] && %P <= 65535}
	}
	.fr.nb.nmap.opt.low insert end 0
	ttk::entry .fr.nb.nmap.opt.high -width 6 -validate key -validatecommand {
		expr {[string is int %P] && %P <= 65535}
	}
	.fr.nb.nmap.opt.high insert end 65535

	pack .fr.nb.nmap.opt -fill both -expand yes -padx 5 -pady 5
	pack .fr.nb.nmap.opt.range -side left
	pack .fr.nb.nmap.opt.low -side left
	pack [ttk::label .fr.nb.nmap.opt.label2 -text { and }] -side left
	pack .fr.nb.nmap.opt.high -side left
}

################################################################################
# Process functions                                                            #
################################################################################

proc run_command {program params} {
	set command [join [list $program {*}$params]]

	# executes command, redirects stderr to stdout
	if [catch {set ::channel [open "| $command 2>@ stdout"]} output] {
		.fr.output.tb insert end $output
	} else {
		set tab [.fr.nb select]

		clear_output
		$tab.host.submit configure -state disabled
		.fr.output.stop configure -state normal

		fileevent $output readable "capture_output $output"
	}
}

proc capture_output {output} {
	if [eof $output] {
		set tab [.fr.nb select]

		$tab.host.submit configure -state normal
		.fr.output.stop configure -state disabled

		catch {close $output}
	} else {
		.fr.output.clear configure -state normal

		gets $output line
		append line \n

		.fr.output.tb insert end $line
		.fr.output.tb see end
	}
}

proc clear_output {} {
	.fr.output.tb delete 0.0 end
	.fr.output.clear configure -state disabled
}

proc toggle_submit {} {
	set tab [.fr.nb select]
	set submit $tab.host.submit
	set value [$tab.host.host get]

	if {[info command $submit] ne {}} {
		if {[string length $value] > 0} {
			$submit configure -state normal
		} else {
			$submit configure -state disabled
		}
	}
}

proc start_execution {} {
	set tab [.fr.nb select]
	$tab.host.submit invoke
}

proc stop_execution {} {
	set tab [.fr.nb select]
	set submit $tab.host.submit

	catch {close $::channel}

	.fr.output.stop configure -state disabled

	if {[info command $submit] ne {}} {
		$submit configure -state normal
	}
}

################################################################################
# IP functions                                                                 #
################################################################################

proc get_local_ip {} {
	# picks random port
	set port [expr {int(1024 + rand() * (65535 - 1024))}]

	set tss [socket -server tserv $port]
	set ts2 [socket [info hostname] $port]
	set ip [lindex [fconfigure $ts2 -sockname] 0]

	close $tss
	close $ts2

	return $ip
}

proc get_remote_ip {} {
	set url $::ip_site

	set http [::http::geturl $url]
	set ip [::http::data $http]

	return [string trim $ip]
}

################################################################################
# Main function                                                                #
################################################################################

proc main {} {
	make_window $::default_width $::default_height
	make_widgets
}

main