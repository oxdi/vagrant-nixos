module VagrantPlugins
	module Nixos
		##############################################
		# Not sure if this is legit. But We'll use this module
		# to store the state of the nix configuration and handle
		# sending it to the machine.
		#############################################

		@@imports = {}

		# send file to machine
		def self.write_config(machine, filename, conf)
			if @@imports[machine.id].nil?
				@@imports[machine.id] = {}
			end
			@@imports[machine.id][filename] = true
			_write_config(machine, filename, conf)
		end

		def self.rebuild(machine)
			conf_paths = if @@imports[machine.id].nil?
				[]
			else
				@@imports[machine.id].keys.inject([]) do |paths, filename|
					paths << "./#{filename}"
				end
			end
			conf = <<-NIX
{ config, pkgs, ... }:

#
# This file is managed by the vagrant-nixos plugin. So hands off!
#

{
	imports = [
		#{conf_paths.join("\n\t\t")}
	];
}
			NIX
			_write_config(machine, "vagrant.nix", conf)
			machine.communicate.tap do |comm|
				comm.sudo("nixos-rebuild switch")
			end
		end

		protected

		# send file to machine
		def self._write_config(machine, filename, conf)
			temp = Tempfile.new("vagrant")
			temp.binmode
			temp.write(conf)
			temp.close
			machine.communicate.tap do |comm|
	            comm.upload(temp.path, "/tmp/#{filename}")
	            comm.sudo("mv /tmp/#{filename} /etc/nixos/#{filename}")
	        end
		end
	end
end