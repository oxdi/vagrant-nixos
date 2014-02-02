module VagrantPlugins
	module Nixos
		class Provisioner < Vagrant.plugin("2", :provisioner)
			# Called with the root configuration of the machine so the provisioner
	        # can add some configuration on top of the machine.
	        #
	        # During this step, and this step only, the provisioner should modify
	        # the root machine configuration to add any additional features it
	        # may need. Examples include sharing folders, networking, and so on.
	        # This step is guaranteed to be called before any of those steps are
	        # done so the provisioner may do that.
	        #
	        # No return value is expected.
	        def configure(root_config)
	        end

	        # This is the method called when the actual provisioning should be
	        # done. The communicator is guaranteed to be ready at this point,
	        # and any shared folders or networks are already setup.
	        #
	        # No return value is expected.
	        def provision
	        end
	    end
	end
end