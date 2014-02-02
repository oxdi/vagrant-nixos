
module VagrantPlugins
	module Nixos
		class Config < Vagrant.plugin(2, :config)

			# Override NIX_PATH.
			attr_accessor :NIX_PATH

			def initialize
				@NIX_PATH = UNSET_VALUE
			end

			def finalize!
				@NIX_PATH = nil if @NIX_PATH == UNSET_VALUE
			end

		end
	end
end