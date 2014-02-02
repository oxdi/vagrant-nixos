begin
	require "vagrant"
rescue LoadError
	raise "The Nixos plugin must be run within Vagrant."
end

# This is a sanity check to make sure no one is attempting to install
# this into an early Vagrant version.
if Vagrant::VERSION < "1.2.0"
	raise "The Nixos plugin is only compatible with Vagrant 1.2+"
end

module VagrantPlugins
	module Nixos

		@@nix_imports = {}

		class Plugin < Vagrant.plugin("2")
			name "nixos"
			description <<-DESC
			This plugin installs nixos guest capabilities.
			DESC

			guest("nixos", "linux") do
				require_relative "guest"
				Guest
			end

			guest_capability("nixos", "configure_networks") do
				require_relative "cap/configure_networks"
				Cap::ConfigureNetworks
			end

			provisioner "nix" do
				require_relative "provisioner"
				Provisioner
			end

			config "nix_path" do
				require_relative "config"
				Config
			end
		end

		def self._write_nix_config(comm, filename, conf)
			temp = Tempfile.new("vagrant")
			temp.binmode
			temp.write(conf)
			puts "---#{filename}----"
			puts conf
			temp.close
            comm.upload(temp.path, "/tmp/#{filename}")
            comm.sudo("mv /tmp/#{filename} /etc/nixos/#{filename}")
		end

		def self.write_nix_config(comm, filename, conf)
			@@nix_imports[filename] = true
			_write_nix_config(comm, filename, conf)
		end

		def self.rebuild(comm)
			conf_paths = @@nix_imports.keys.inject([]) do |paths, filename|
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
			_write_nix_config(comm, "vagrant.nix", conf)
			comm.sudo("__ETC_PROFILE_SOURCED=0 nixos-rebuild switch", { :shell => "sh" })
		end
	end
end
