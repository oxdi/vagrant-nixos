require 'set'
require 'tempfile'


module VagrantPlugins
	module Nixos
		module Cap
			class ChangeHostName
				include Vagrant::Util

				def self.nix_module(name)
					<<-NIX
{ config, pkgs, ... }:
{
	networking.hostName = "#{name}";
}
					NIX
				end

				def self.change_host_name(machine, name)
					machine.communicate.tap do |comm|
			            Nixos.write_nix_config(comm, "vagrant-hostname.nix", nix_module(name))
			            Nixos.rebuild(comm)
			        end
			    end

			end
		end
	end
end

