module Bozo

  # Class for generating configuration objects.
  class Configuration

    # Create a new instance.
    def initialize
      @root = ConfigurationGroup.new
      @group_stack = [@root]
    end

    # Begin the definition of a group with the given name.
    #
    # @param [Symbol] name
    #     The name of the group.
    def group(name)
      new_group = @group_stack.last.ensure_child name
      @group_stack.push new_group
      yield
      @group_stack.pop
    end

    # Set the value of the given key within the active group.
    #
    # @param [Symbol] key
    #     The key to set the value of within the active group.
    # @param [Object] value
    #     The value to set the key to within the active group.
    def set(key, value)
      @group_stack.last.set_value(key, value)
    end

    # Load the specified file as an additional configuration file.
    #
    # == Usage
    #
    # Configuration files specify a hash of hashes in a more readable format.
    # For example:
    #
    #   group :example do
    #     set :one, 'foo'
    #     set :two, 'bar'
    #   end
    #
    # Internally creates a hash like:
    #
    #   {:example => {:one => 'foo', :two => 'bar'}}
    #
    # A configuration file can overwrite the values specified by a preceding one
    # without error. Groups can be opened and closed as desired and nesting
    # groups is possible.
    #
    # @param [String] path
    #     The path of the configuration file.
    def load(path)
      instance_eval IO.read(path), path
    end

    # Yields the internal binding of the configuration to the given block.
    #
    # @param [Proc] block
    #     The block to yield the configuration's internal binding to.
    def apply(&block)
      @root.apply(block)
    end

    # Return the current state of the configuration.
    def inspect
      @root.inspect
    end

    private

    # Class for controlling the creation and retrieval of configuration
    # groups and values.
    #
    # Should not be used outside of this class.
    class ConfigurationGroup # :nodoc:

      # Create a new instance.
      def initialize(*parents)
        @parents = parents
        @hash = {}
      end

      # Enables the fluent retrieval of groups within the hash.
      def method_missing(sym, *args, &block)
        raise missing_child sym unless @hash.key? sym
        @hash[sym]
      end

      # Ensures the hash contains a child hash for the specified key and
      # returns it.
      #
      # @param [Symbol] key
      #     The key that must contain a child hash.
      def ensure_child(key)
        @hash[key] = ConfigurationGroup.new(@parents + [key]) unless @hash.key? key
        @hash[key]
      end

      # Sets the value of the specified key.
      #
      # @param [Symbol] key
      #     The key to set the value of.
      # @param [Object] value
      #     The value to set for the specified key.
      def set_value(key, value)
        @hash[key] = value
      end

      # Yields the internal binding of the configuration group to the given
      # block.
      #
      # @param [Proc] block
      #     The block to yield the internal binding to.
      def apply(block)
        block.call(binding)
      end

      # Return the current state of the configuration.
      def inspect
        @hash.inspect
      end

      private
      
      # Create a new error specifying that an attempt was made to retrieve a
      # child that does not exist.
      #
      # @param [Symbol] sym
      #     The key of the requested child.
      def missing_child(sym)
        Bozo::ConfigurationError.new "#{@parents.any? ? @parents.join('.') : 'Root'} does not contain a value or group called '#{sym}' - known keys: #{@hash.keys.join(', ')}"
      end

    end

  end

end