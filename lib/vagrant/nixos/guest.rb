module VagrantPlugins
	module GuestNixos
		class Guest < Vagrant.plugin("2", :guest)
			def detect?(machine)
				machine.communicate.test("test -f /etc/nixos/configuration.nix")
			end
		end
	end
end