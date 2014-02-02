module VagrantPlugins
	module Nixos
		##############################################
		# Not sure if this is legit. But We'll use this module
		# to store the state of the nix configuration and handle
		# sending it to the machine.
		#############################################

		@@imports = {}

		# send file to machine
		def self.write_config(machine, filename, conf)
			include_config(machine, filename)
			_write_config(machine, filename, conf)
		end

		# mark a file that should be imported to the main config
		def self.include_config(machine, filename)
			if @@imports[machine.id].nil?
				@@imports[machine.id] = {}
			end
			@@imports[machine.id][filename] = true
		end

		def self.rebuild(machine, nix_env=nil)
			rebuild_cmd = "nixos-rebuild switch"
			conf = "{ config, pkgs, ... }:\n{"
			# imports
			conf_paths = if @@imports[machine.id].nil?
				[]
			else
				@@imports[machine.id].keys.inject([]) do |paths, filename|
					paths << "./#{filename}"
				end
			end
			conf << %{
				imports = [
					#{conf_paths.join("\n\t\t")}
				];
			}
			# default NIX_PATH
			if nix_env
				conf << %{
					config.environment.shellInit = ''
						export NIX_PATH=#{nix_env}:$NIX_PATH
					'';
				}
				rebuild_cmd = "NIX_PATH=#{nix_env}:$NIX_PATH #{rebuild_cmd}"
			end
			conf << "}"
			# output / build the config
			_write_config(machine, "vagrant.nix", conf)
			machine.communicate.tap do |comm|
				comm.sudo(rebuild_cmd)
			end
		end

		protected

		# send file to machine
		def self._write_config(machine, filename, conf)
			temp = Tempfile.new("vagrant")
			temp.binmode
			temp.write(conf)
			temp.close
			machine.communicate.tap do |comm|
	            comm.upload(temp.path, "/tmp/#{filename}")
	            comm.sudo("mv /tmp/#{filename} /etc/nixos/#{filename}")
	        end
		end
	end
end