#!/usr/bin/ruby
# encoding: utf-8

require 'glib2'
require 'gtk2'
require 'MfsDiskDrive.rb'
# require 'MfsSinglePartition.rb'
require 'MfsTranslator.rb'

def error_dialog(title, text) 
	dialog = Gtk::Dialog.new(
		title,
		$mainwindow,
		Gtk::Dialog::MODAL,
		[ Gtk::Stock::OK, Gtk::Dialog::RESPONSE_OK ]
	)
	dialog.default_response = Gtk::Dialog::RESPONSE_OK
	dialog.has_separator = false
	label = Gtk::Label.new
	label.set_markup(text)
	label.wrap = true
	image = Gtk::Image.new(Gtk::Stock::DIALOG_ERROR, Gtk::IconSize::DIALOG)
	hbox = Gtk::HBox.new(false, 5)
	hbox.border_width = 10
	hbox.pack_start_defaults(image)
	hbox.pack_start_defaults(label)
	dialog.vbox.add(hbox)
	dialog.show_all
	dialog.run { |resp|
		dialog.destroy
		return true
	}
end

def info_dialog(title, text) 
	dialog = Gtk::Dialog.new(
		title,
		$mainwindow,
		Gtk::Dialog::MODAL,
		[ Gtk::Stock::OK, Gtk::Dialog::RESPONSE_OK ]
	)
	dialog.default_response = Gtk::Dialog::RESPONSE_OK
	dialog.has_separator = false
	label = Gtk::Label.new
	label.set_markup(text)
	label.wrap = true
	image = Gtk::Image.new(Gtk::Stock::DIALOG_INFO, Gtk::IconSize::DIALOG)
	hbox = Gtk::HBox.new(false, 5)
	hbox.border_width = 10
	hbox.pack_start_defaults(image)
	hbox.pack_start_defaults(label)
	dialog.vbox.add(hbox)
	dialog.show_all
	dialog.run { |resp|
		dialog.destroy
		return true
	}
end

def question_dialog(title, text, default=false)
	dialog = Gtk::Dialog.new(
		title,
		$mainwindow,
		Gtk::Dialog::MODAL,
		[ Gtk::Stock::YES, Gtk::Dialog::RESPONSE_YES ],
		[ Gtk::Stock::NO, Gtk::Dialog::RESPONSE_NO ]
	)
	if default == true
		dialog.default_response = Gtk::Dialog::RESPONSE_YES
	else
		dialog.default_response = Gtk::Dialog::RESPONSE_NO
	end
	dialog.has_separator = false
	label = Gtk::Label.new
	label.set_markup(text)
	label.wrap = true
	image = Gtk::Image.new(Gtk::Stock::DIALOG_WARNING, Gtk::IconSize::DIALOG)
	hbox = Gtk::HBox.new(false, 5)
	hbox.border_width = 10
	hbox.pack_start_defaults(image)
	hbox.pack_start_defaults(label)
	dialog.vbox.add(hbox)
	dialog.show_all
	dialog.run { |resp|
		case resp
		when Gtk::Dialog::RESPONSE_YES
			dialog.destroy
			return true
		else
			dialog.destroy
			return false
		end
	}
end

def check_samba
	running = false
	 IO.popen("ps waux") { |line|
		while line.gets 
			ltoks = $_.strip.split
			0.upto(9) { |n| ltoks.delete_at(0) }
			running = true if ltoks[0] == "istgt"
		end
	}
	return running 
end

def set_active(gobutton, infolabel)
	if check_samba == true
		adds = get_ipaddr 
		gobutton.label = @tl.get_translation("stopsmb")
		infolabel.set_markup(@tl.get_translation("statuson").gsub("IPADDRESSES", adds.join(", ") ) ) 
		gobutton.image = Gtk::Image.new(Gtk::Stock::CANCEL, Gtk::IconSize::BUTTON)
	else
		gobutton.label = @tl.get_translation("startsmb")
		infolabel.set_markup(@tl.get_translation("statusoff"))
		gobutton.image = Gtk::Image.new(Gtk::Stock::APPLY, Gtk::IconSize::BUTTON)
	end
end

def get_ipaddr
	addr = Array.new
	IO.popen("ip address") { |line|
		while line.gets
			ltoks = $_.strip.split
			if ltoks[0] == "inet"
				add = ltoks[1].split("/")[0]
				puts add 
				addr.push(add) unless add =~ /^127/
			end
		end
	}
	return addr 
end

def start_stop_smbd
	if check_samba == false
		start_istgt(get_ipaddr[0])
		@rwradio.sensitive = false
	else
		system("killall -15 istgt")
		sleep 2
		system("killall -9 istgt")
		@rwradio.sensitive = true
	end
end

def start_istgt(ipaddr)
	puts "Using IP address #{ipaddr}"
	drives = Array.new
	Dir.entries("/sys/block").each { |l|
		drives.push(MfsDiskDrive.new(l, false)) if l =~ /[a-z]$/  || l =~ /nvme[0-9]n[0-9]$/ || l =~ /mmcblk[0-9]$/
	}
	# Copy base configuration:
	configout = File.new("/etc/istgt/istgt.conf.cbrescue", "w")
	File.open("config/istgt.conf").each { |line|
		configout.write(line.gsub("IPADDRESS", ipaddr))
	}
	lun = 0
	drives.each { |d|
		if d.mounted == false
			lun += 1
			configout.write("[LogicalUnit#{lun}]\n")
			configout.write("  Comment \"Hard Disk #{lun}\"\n")
			configout.write("  TargetName #{d.device}\n")
			configout.write("  TargetAlias \"Data Disk#{lun}\"\n")
			configout.write("  Mapping PortalGroup1 InitiatorGroup1\n")
			configout.write("  AuthMethod Auto\n")
			configout.write("  AuthGroup AuthGroup1\n")
			if @rwradio.active? == true
				configout.write("  ReadOnly No\n")
			else
				configout.write("  ReadOnly Yes\n")
			end
			configout.write("  UseDigest Auto\n")
			configout.write("  UnitType Disk\n")
			configout.write("  LUN0 Storage /dev/#{d.device} Auto\n\n")
		end
	}
	configout.close
	system("cp -v /usr/share/lesslinux/notfallcd4/config/auth.conf /etc/istgt/auth.conf.cbrescue")
	system("istgt -c /etc/istgt/istgt.conf.cbrescue")
end

lang = ENV['LANGUAGE'][0..1]
lang = ENV['LANG'][0..1] if lang.nil?
lang = "en" if lang.nil?
tlfile = "runiscsitgt.xml"
tlfile = "/usr/share/lesslinux/drivetools/runiscsitgt.xml" if File.exists?("/usr/share/lesslinux/drivetools/runiscsitgt.xml")
tl = MfsTranslator.new(lang, tlfile)
@tl = tl

# Global variables

@pwentered = false

# Frame for general info

cframe = Gtk::Frame.new(tl.get_translation("step1"))
infolabel= Gtk::Label.new
infolabel.wrap = true
infolabel.width_request = 400
infolabel.set_markup(tl.get_translation("info"))
cframe.add(infolabel) 

# Frame for Status and Go-Button

uframe = Gtk::Frame.new(tl.get_translation("step2"))
ubox = Gtk::VBox.new(false, 5)
gostop = Gtk::Button.new(tl.get_translation("startsmb"))
gostop.height_request = 32
gostop.width_request = 400
staterunning = Gtk::Label.new
staterunning.wrap = true
staterunning.width_request = 400
staterunning.set_markup(tl.get_translation("statusoff"))
ubox.pack_start_defaults(staterunning)
@rwradio = Gtk::CheckButton.new(tl.get_translation("export_writable"))
ubox.pack_start_defaults(@rwradio)
ubox.pack_start_defaults(gostop)
uframe.add(ubox)

# VBox for stacking widgets

lvb = Gtk::VBox.new
lvb.pack_start_defaults(cframe)
lvb.pack_start_defaults(uframe)
# lvb.pack_start_defaults(progressframe)

window = Gtk::Window.new
window.border_width = 10
window.set_title(tl.get_translation("head"))
window.window_position = Gtk::Window::POS_CENTER_ALWAYS
# window.deletable = false
# window.decorated = false
# window.width_request = 600
# window.height_request = 400
window.add lvb

window.signal_connect("delete_event") {
        puts "delete event occurred"
        false
}

window.signal_connect("destroy") {
        puts "destroy event occurred"
        Gtk.main_quit
}

gostop.signal_connect("clicked") {
	start_stop_smbd 
	sleep 1 
	set_active(gostop, staterunning) 
}

set_active(gostop, staterunning) 
# set_active_boxes(locradio, pwentry, revradio, hostentry, staterunning, gostop)
window.show_all
# shutdown.grab_default
# shutdown.grab_focus

Gtk.main



