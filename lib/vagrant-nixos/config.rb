
module VagrantPlugins
	module Nixos
		class Config < Vagrant.plugin("2", :config)
			attr_accessor :inline
			attr_accessor :path
			attr_accessor :NIX_PATH

			def initialize
				@inline      = UNSET_VALUE
				@path        = UNSET_VALUE
				@NIX_PATH    = UNSET_VALUE
			end

			def finalize!
				@inline      = nil if @inline == UNSET_VALUE
				@path        = nil if @path == UNSET_VALUE
				@NIX_PATH    = nil if @NIX_PATH == UNSET_VALUE
			end

			def validate(machine)
				errors = _detected_errors

				if path && inline
					errors << "Both :path and :inline were set for nixos provisioner"
				elsif !path && !inline
					errors << "Missing :inline or :path for nixos provisioner"
				end

				if path && !File.exist?(path)
					errors << "Invalid path #{path}"
				end

				{ "nixos provisioner" => errors }
			end

		end
	end
end