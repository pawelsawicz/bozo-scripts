require 'erubis'

module Bozo::Hooks
  
  # Hook for creating files based upon configuration files and ERB-style
  # templates before any compilation occurs.
  # 
  # == Overview
  # 
  # This hook is primarily intended for generating config files with shared
  # values but it is capable of generating whatever files you want. Each
  # instance of the hook is isolated from the anothers so you could specify
  # multiple hooks to work with different configurations and templates if you
  # wished.
  # 
  # By default the hook will load <tt>default.rb</tt> followed by
  # <tt>[environment].rb</tt> from the configured config_path if the file
  # exists. It will then load any files explicitly required through the
  # config_file method.
  # 
  # == Hook configuration
  # 
  #   pre_compile :file_templating do |t|
  #     t.config_path 'somewhere' # defaults to 'config' if not specified
  #     t.config_file 'my/specific/file.rb' # must be a specific file
  #     t.source_files 'src/**/*.config.template' # can use glob format
  #   end
  # 
  # Source files are expected to have an additional extension compared to the
  # target file. For example, a source file of
  # <tt>src/csharp/Project/Project.config.template</tt> will generate the file
  # <tt>src/csharp/Project/Project.config</tt>.
  # 
  # == Configuration files
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
  # without error. Groups can be opened and closed as desired but note that
  # nests groups are not allowed.
  # 
  # == Template files
  # 
  # To use a value within an ERB template you specify the hash hierarchy as if
  # they were method names rather than having to use the full hash syntax.
  # 
  # Therefore, this is valid:
  # 
  #   Foo is <%= example.one %>
  # 
  # Whilst this is *not* valid:
  # 
  #   Foo is <%= self[:example][:one] %>
  # 
  # If a template uses a value that is not specified within the configuration
  # then the hook will raise an error and halt the build.
  class FileTemplating
    
    # Creates a new instance.
    def initialize
      @config_path = 'config'
      @source_file_globs = []
      @config_files = []
    end
    
    # Sets the path of the directory within which the hook should look for the
    # default configuration files.
    # 
    # @param [String] path
    #     The path to the directory containing the default configuration 
    #     files.
    def config_path(path)
      @config_path = path
    end
    
    # Adds a specific file to load configuration from.
    # 
    # @param [String] path
    #     The path to a configuration file.
    def config_file(path)
      @config_files << path
    end
    
    # Adds a set of source files to be generated.
    # 
    # @param [String] glob
    #     A glob that points to a set of files that should pass through the 
    #     template.
    def source_files(glob)
      @source_file_globs << glob
    end
    
    # Generate all the files matching the configuration.
    def pre_compile
      log_info '' # formatting
      log_info 'Generating files'
      
      config = load_configuration
      
      @source_file_globs.each do |glob|
        Dir[glob].each {|file| generate_file config, file}
      end
    end
    
    private
    
    # Create a new configuration object loading the default files when present
    # and all the explicitly added configuration files.
    def load_configuration
      config = Configuration.new
      
      load_default_files config
      @config_files.each {|f| config.load f}
      
      config
    end
    
    # Generate the file relating to the template file using the given
    # configuration.
    # 
    # @param [Configuration] config
    #     The configuration that should be used to generate the file.
    # @param [String] template_file
    #     The path of the template file that should be filled using the
    #     configuration.
    def generate_file(config, template_file)
      target_file = template_file.sub /\.[^\.]+$/, ''
      
      log_debug "Found template #{template_file}"
      template_content = IO.read template_file
      
      log_debug "Generating #{target_file}"
      transformed_content = config.transform(template_content)
      
      File.open(target_file, 'w+') {|f| f.write transformed_content}
    end
    
    # Load the default files from the configuration directory if they are
    # present.
    # 
    # @param [Configuration] config
    #     The configuration object to load the files into if they are present.
    def load_default_files(config)
      ['default.rb', "#{environment}.rb"].each do |file|
        path = File.join(@config_path, file)
        config.load path if File.exist? path
      end
    end
    
    # Should not be used outside of this class.
    class Configuration # :nodoc:

      # Create a new instance.
      def initialize
        @configuration = GroupsHash.new
      end
      
      # Begin the definition of a group with the given name.
      # 
      # @param [Symbol] name
      #     The name of the group.
      def group(name)
        raise nested_group unless @active_group.nil?
        @active_group = @configuration.ensure_child name
        yield
        @active_group = nil
      end

      # Set the value of the given key within the active group.
      # 
      # @param [Symbol] key
      #     The key to set the value of within the active group.
      # @param [Object] value
      #     The value to set the key to within the active group.
      def set(key, value)
        raise value_outside_group if @active_group.nil?
        @active_group.set_value(key, value)
      end
      
      # Load the specified file as an additional configuration file.
      # 
      # @param [String] path
      #     The path of the configuration file.
      def load(path)
        instance_eval IO.read(path), path
      end

      # Transform the given template using the current configuration to
      # replace values.
      # 
      # @param [String] template
      #     The template content.
      def transform(template)
        erb_template = Erubis::Eruby.new template
        @configuration.evaluate_template(erb_template)
      end

      # Return the current state of the configuration.
      def inspect
        @configuration.inspect
      end
      
      private
      
      # Create a new error specifying that a value was set outside the bounds
      # of a group.
      def value_outside_group
        Bozo::ConfigurationError.new "Values can only be set within a group"
      end

      # Create a new error specifying that an attempt was made to create a
      # nested group.
      def nested_group
        Bozo::ConfigurationError.new "Groups cannot be nested"
      end

      # Class for controlling the creation and retrieval of configuration
      # groups.
      # 
      # Should not be used outside of this class.
      class GroupsHash # :nodoc:

        # Create a new instance.
        def initialize
          @hash = {}
        end

        # Enables the fluent retrieval of groups within the hash.
        def method_missing(sym, *args, &block)
          raise missing_group sym unless @hash.key? sym
          @hash[sym]
        end

        # Ensures the hash contains a child hash for the specified key and
        # returns it.
        # 
        # @param [Symbol] key
        #     The key that must contain a child hash.
        def ensure_child(key)
          @hash[key] = GroupValuesHash.new(key) unless @hash.key? key
          @hash[key]
        end

        # Resolves a template using itself as the binding context.
        # 
        # @param [Erubis::Eruby] template
        #     The template to generate the result for.
        def evaluate_template(template)
          template.result(binding)
        end

        # Return the current state of the configuration.
        def inspect
          @hash.inspect
        end
        
        private
        
        # Create a new error specifying that an attempt was made to retrieve a
        # group that does not exist.
        # 
        # @param [Symbol] sym
        #     The name of the group.
        def missing_group(sym)
          Bozo::ConfigurationError.new "Configuration does not contain a group called '#{sym}' - #{@hash.keys}"
        end

      end

      # Class for controlling the creation and retrieval of values within a
      # configuration group.
      # 
      # Should not be used outside of this class.
      class GroupValuesHash # :nodoc:

        # Create a new instance.
        # 
        # @param [Symbol] group
        #     The name of the parent group.
        def initialize(group)
          @group = group
          @hash = {}
        end

        # Enables the fluent retrieval of values within the hash.
        def method_missing(sym, *args, &block)
          raise missing_key sym unless @hash.key? sym
          @hash[sym]
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

        # Return the current state of the configuration.
        def inspect
          @hash.inspect
        end
        
        private
        
        # Create a new error specifying that an attempt was made to retrieve a
        # key that does not exist.
        # 
        # @param [Symbol] sym
        #     The key that does not exist.
        def missing_key(sym)
          Bozo::ConfigurationError.new "Configuration group '#{@group}' does not contain a value for '#{sym}' - #{@hash.inspect}"
        end

      end

    end
    
  end
  
end