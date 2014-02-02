
module VagrantPlugins
	module Nixos
		class Config < Vagrant.plugin(2, :config)

			# Override NIX_PATH.
			attr_accessor :path

			attr_accessor :imports

			def initialize
				@path = UNSET_VALUE
				@imports = UNSET_VALUE
			end

			def finalize!
				@path = nil if @path == UNSET_VALUE
				@imports = {} if @path == UNSET_VALUE
			end


		end
	end
end