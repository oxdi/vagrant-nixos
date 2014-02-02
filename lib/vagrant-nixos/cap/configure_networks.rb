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
						if network[:ip].empty?
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

			            # Perform the careful dance necessary to reconfigure
			            # the network interfaces
			            temp = Tempfile.new("vagrant")
			            temp.binmode
			            temp.write(conf)
			            temp.close

			            puts conf

			            # add the network config
			            filename = "vagrant-interfaces.nix"
			            comm.upload(temp.path, "/tmp/#{filename}")
			            comm.sudo("mv /tmp/#{filename} /etc/nixos/#{filename}")

			            # TODO: check that the network config is referenced in vagrant.nix

			            # cleanup
			            temp.unlink
			        end
			    end

			end
		end
	end
end