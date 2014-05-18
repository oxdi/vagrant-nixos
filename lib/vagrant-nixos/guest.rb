module VagrantPlugins
  module Nixos
    class Guest < Vagrant.plugin("2", :guest)

      attr_accessor :nix_imports

      def detect?(machine)
        machine.communicate.test("test -f /etc/nixos/configuration.nix")
      end

    end
  end
end
