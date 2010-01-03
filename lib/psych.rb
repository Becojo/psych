require 'psych/visitable'

require 'psych/nodes/node'
require 'psych/nodes/stream'
require 'psych/nodes/document'
require 'psych/nodes/sequence'
require 'psych/nodes/scalar'
require 'psych/nodes/mapping'
require 'psych/nodes/alias'

require 'psych/visitors'

require 'psych/handler'
require 'psych/tree_builder'
require 'psych/parser'
require 'psych/ruby'
require 'psych/omap'
require 'psych/set'
require 'psych/psych'

###
# Psych is a YAML parser and emitter.  Psych leverages
# libyaml[http://libyaml.org] for it's YAML parsing and emitting capabilities.
# In addition to wrapping libyaml, Psych also knows how to serialize and
# de-serialize most Ruby objects to and from the YAML format.
#
# == YAML Parsing
#
# Psych provides a range of interfaces for parsing a YAML document ranging from
# low level to high level, depending on your parsing needs.  At the lowest
# level, is an event based parser.  Mid level is access to the raw YAML AST,
# and at the highest level is the ability to unmarshal YAML to ruby objects.
#
# === Low level parsing
#
# The lowest level parser should be used when the YAML input is already known,
# and the developer does not want to pay the price of building an AST or
# automatic detection and conversion to ruby objects.  See Psych::Parser for
# more information on using the event based parser.
#
# === Mid level parsing
#
# Psych provides access to an AST produced from parsing a YAML document.  This
# tree is built using the Psych::Parser and Psych::TreeBuilder.  The AST can
# be examined and manipulated freely.  Please see Psych::yaml_ast,
# Psych::Nodes, and Psych::Nodes::Node for more information on dealing with
# YAML syntax trees.
#
# === High level parsing
#
# The high level YAML parser provided by Psych simply takes YAML as input and
# returns a Ruby data structure.  For information on using the high level parser
# see Psych.load
#
# == YAML Emitting
#
# Psych provides a range of interfaces ranging from low to high level for
# producing YAML documents.  Very similar to the YAML parsing interfaces, Psych
# provides at the lowest level, an event based system, mid-level is building
# a YAML AST, and the highest level is converting a Ruby object straight to
# a YAML document.
#
# === Low level emitting
#
# The lowest level emitter is an event based system.  Events are sent to a
# Psych::Emitter object.  That object knows how to convert the events to a YAML
# document.  This interface should be used when document format is known in
# advance or speed is a concern.  See Psych::Emitter for more information.
#
# === Mid level emitting
#
# At the mid level is building an AST.  This AST is exactly the same as the AST
# used when parsing a YAML document.  Users can build an AST by hand and the
# AST knows how to emit itself as a YAML document.  See Psych::Nodes,
# Psych::Nodes::Node, and Psych::TreeBuilder for more information on building
# a YAML AST.
#
# === High level emitting
#
# The high level emitter has the easiest interface.  Psych simply takes a Ruby
# data structure and converts it to a YAML document.  See Psych.dump for more
# information on dumping a Ruby data structure.

module Psych
  # The version is Psych you're using
  VERSION         = '1.0.0'

  # The version of libyaml Psych is using
  LIBYAML_VERSION = Psych.libyaml_version.join '.'

  ###
  # Load +yaml+ in to a Ruby data structure.  If multiple documents are
  # provided, the object contained in the first document will be returned.
  #
  # Example:
  #
  #   Psych.load("--- a")           # => 'a'
  #   Psych.load("---\n - a\n - b") # => ['a', 'b']
  def self.load yaml
    parse(yaml).to_ruby
  end

  ###
  # Parse a YAML string in +yaml+.  Returns the first object of a YAML AST.
  #
  # Example:
  #
  #   Psych.load("---\n - a\n - b") # => #<Psych::Nodes::Sequence:0x00>
  #
  # See Psych::Nodes for more information about YAML AST.
  def self.parse yaml
    yaml_ast(yaml).children.first.children.first
  end

  ###
  # Parse a YAML string in +yaml+.  Returns the full AST for the YAML document.
  # This method can handle multiple YAML documents contained in +yaml+.
  #
  # Example:
  #
  #   Psych.load("---\n - a\n - b") # => #<Psych::Nodes::Stream:0x00>
  #
  # See Psych::Nodes for more information about YAML AST.
  def self.yaml_ast yaml
    parser = Psych::Parser.new(TreeBuilder.new)
    parser.parse yaml
    parser.handler.root
  end

  ###
  # Dump Ruby object +o+ to a YAML string using +options+.
  #
  # Example:
  #
  #   Psych.dump(['a', 'b'])  # => "---\n- a\n- b\n"
  def self.dump o, options = {}
    visitor = Psych::Visitors::YAMLTree.new options
    visitor.accept o
    visitor.tree.to_yaml
  end

  ###
  # Load multiple documents given in +yaml+, yielding each document to
  # the block provided.
  def self.load_documents yaml, &block
    yaml_ast(yaml).children.each do |child|
      block.call child.to_ruby
    end
  end

  @domain_types = {}
  def self.add_domain_type domain, type_tag, &block
    @domain_types[type_tag] = [domain, block]
  end
  class << self; attr_accessor :domain_types; end
end
