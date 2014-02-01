require 'set'
require 'tempfile'

require "vagrant/util/template_renderer"

module VagrantPlugins
	module GuestNixos
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

				def self.nix_network_expr(exprs)
					<<-NIX
						config.networking.useDHCP = true;
						config.networking.interfaces = [
							#{exprs.join("\n")}
						];
					NIX
				end

				def self.configure_networks(machine, networks)
					machine.communicate.tap do |comm|
						# build the network config
			            expr = networks.inject("") do |network, exprs|
			            	exprs = interface_exprs(network)
			            	exprs
			            end

			            # Perform the careful dance necessary to reconfigure
			            # the network interfaces
			            temp = Tempfile.new("vagrant")
			            temp.binmode
			            temp.write(expr)
			            temp.close

			            puts expr

			            # add the network config
			            comm.upload(temp.path, "/etc/nixos/vagrant-network.nix")

			            # TODO: check that the network config is referenced in vagrant.nix

			            # cleanup
			            temp.unlink
			        end
			    end

			end
		end
	end
end