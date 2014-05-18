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

        def self.nix_module(networks)
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
            networking.usePredictableInterfaceNames = false;
            networking.useDHCP = true;
            networking.interfaces = [
              #{exprs.join("\n")}
            ];
          }
          NIX
        end

        def self.configure_networks(machine, networks)
          if Nixos.write_config(machine, "vagrant-interfaces.nix", nix_module(networks))
            Nixos.rebuild(machine)
          end
        end

      end
    end
  end
end
