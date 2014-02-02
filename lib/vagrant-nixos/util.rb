module VagrantPlugins
	module Nixos
		##############################################
		# Not sure if this is legit. But We'll use this module
		# to store the state of the nix configuration and handle
		# sending it to the machine.
		#############################################

		@@imports = {}

		# Send file to machine and report if it changed
		# See _write_config
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

		def imports
		end

		# rebuild the base vagrant.nix configuration
		def self.rebuild(machine, nix_env=nil)
			# build 
			conf = "{ config, pkgs, ... }:\n{"
			# Add a mock provision file if it is missing as during boot the
			# provisioning file may not be deployed yet.
			if !machine.communicate.test("test -f /etc/nixos/vagrant-provision.nix")
				_write_config(machine, "vagrant-provision.nix", "{ config, pkgs, ... }: {}")
			end
			# imports
			conf_paths = if @@imports[machine.id].nil?
				[]
			else
				@@imports[machine.id].keys.inject([]) do |paths, filename|
					paths << "./#{filename}"
				end
			end
			conf_paths << "./vagrant-provision.nix"
			# construct the nix module
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
			end
			conf << "}"
			# output / build the config
			_write_config(machine, "vagrant.nix", conf)
			rebuild!(machine, nix_env)
		end

		# just do nixos-rebuild
		def self.rebuild!(machine, nix_env=nil)
			rebuild_cmd = "nixos-rebuild switch"
			rebuild_cmd = "NIX_PATH=#{nix_env}:$NIX_PATH #{rebuild_cmd}" if nix_env
			machine.communicate.tap do |comm|
				comm.sudo(rebuild_cmd)
			end
		end

		def self.same?(machine, f1, f2)
			machine.communicate.test("cmp --silent '#{f1}' '#{f2}'")
		end

		protected

		# Send file to machine.
		# Returns true if the uploaded file if different from any 
		# preexisting file, false if the file is indentical
		def self._write_config(machine, filename, conf)
			temp = Tempfile.new("vagrant")
			temp.binmode
			temp.write(conf)
			temp.close
			changed = true
			machine.communicate.tap do |comm|
				source = "/tmp/#{filename}"
				target = "/etc/nixos/#{filename}"
	            comm.upload(temp.path, source)
	            if same?(machine, source, target)
	            	changed = false
	            else
	            	comm.sudo("mv '#{source}' '#{target}'")
	            end
	        end
	        return changed
		end
	end
end

#################################################
# Naughty extending of builtins.
# Add to_nix functions to convert ruby2nix (ish).
#################################################

module Nix
	INDENT_STRING="  "
end

class Symbol
	def to_nix(indent = 0)
		to_s
	end
end

class NilClass
	def to_nix(indent = 0)
		"null"
	end
end

class Hash
	def to_nix(indent = 0)
		"{\n" +
		sort {|a, b| a[0].to_s <=> b[0].to_s}.map do |key, value|
			raise "Key must be a Symbol, not #{key.class}" unless key.is_a?(Symbol)
			Nix::INDENT_STRING * (indent + 1)+ key.to_nix +
			" = " + value.to_nix(indent + 1) + ";"
		end.join("\n") + "\n" +
		Nix::INDENT_STRING * indent + "}"
	end
end

class Array
	def to_nix(indent = 0)
		"[ " + map(&:to_nix).join(" ") + " ]"
	end
end

class String
	def to_nix(indent = 0)
	    # TODO: escape ${var} in string
	    "''#{self}''"
	end
end

class Fixnum
	def to_nix(indent = 0)
	    to_s
	end
end