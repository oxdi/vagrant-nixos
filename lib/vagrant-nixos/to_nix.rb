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