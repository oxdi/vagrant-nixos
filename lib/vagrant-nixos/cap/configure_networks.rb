require 'set'
require 'tempfile'

require "vagrant/util/template_renderer"

module VagrantPlugins
	module Nixos
		module Cap
			class ConfigureNetworks
				include Vagrant::Util

				def self.nix_interface_expr(options)
					<<-NIX
		{ 
			name = "eth#{options[:interface]}";
          	ipAddress = "#{options[:ip]}";
          	subnetMask = "#{options[:netmask]}";
        }
					NIX
				end

				def self.nix_interface_module(networks)
					exprs = networks.inject([]) do |exprs, network|
						# Interfaces without an ip set will fallback to
						# DHCP if useDHCP is set. So skip them.
						if network[:ip].nil? or network[:ip].empty?
							exprs
						else
							exprs << nix_interface_expr(network)
						end
					end
					<<-NIX
{ config, pkgs, ... }:
{
	networking.useDHCP = true;
	networking.interfaces = [
		#{exprs.join("\n")}
	];
}
					NIX
				end

				def self.configure_networks(machine, networks)
					machine.communicate.tap do |comm|
						# build the network config
						conf = nix_interface_module(networks)

						# write out config and build
			            Nixos.write_nix_config(comm, "vagrant-interfaces.nix", conf)
			            Nixos.rebuild(comm)
			        end
			    end

			end
		end
	end
end