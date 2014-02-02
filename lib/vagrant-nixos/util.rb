module VagrantPlugins
	module Nixos
		##############################################
		# Not sure if this is legit. But We'll use the Config
		# to store the state of the nix configuration and handle
		# sending it to the machine.
		#############################################

		# send file to machine
		def self.write_config(machine, filename, conf)
			puts filename
			machine.config.nixos.imports[filename] = true
			_write_config(machine, filename, conf)
		end

		def self.rebuild(machine)
			conf_paths = machine.config.nixos.imports.keys.inject([]) do |paths, filename|
				paths << "./#{filename}"
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
			machine.communicate do |comm|
				_write_nix_config(comm, "vagrant.nix", conf)
				comm.sudo("nixos-rebuild switch")
			end
		end

		protected

		# send file to machine
		def self._write_config(machine, filename, conf)
			temp = Tempfile.new("vagrant")
			temp.binmode
			temp.write(conf)
			puts "---#{filename}----"
			puts conf
			temp.close
			machine.communicate do |comm|
	            comm.upload(temp.path, "/tmp/#{filename}")
	            comm.sudo("mv /tmp/#{filename} /etc/nixos/#{filename}")
	        end
		end
	end
end