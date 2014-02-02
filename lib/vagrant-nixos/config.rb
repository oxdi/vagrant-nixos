
module VagrantPlugins
	module Nixos
		class Config < Vagrant.plugin(2, :config)

			# Override NIX_PATH.
			attr_accessor :path

			def initialize
				@path = ""
			end

			def finalize!
			end
		end
	end
end