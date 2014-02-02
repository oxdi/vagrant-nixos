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
					Nixos.write_config(machine, "vagrant-hostname.nix", nix_module(name))
					Nixos.rebuild(machine)
				end

			end
		end
	end
end

