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
  # <tt>[environment].rb</tt> followed by <tt>[machine_name].rb</tt> from the
  # configured config_path if the file exists. It will then load any files
  # explicitly required through the config_file method.
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
  # without error. Groups can be opened and closed as desired and nesting
  # groups is possible.
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
      template = Erubis::Eruby.new template_content
      
      log_debug "Generating #{target_file}"
      content = config.apply {|binding| template.result(binding)}
      File.open(target_file, 'w+') {|f| f.write(content)}
    end
    
    # Load the default files from the configuration directory if they are
    # present.
    # 
    # @param [Configuration] config
    #     The configuration object to load the files into if they are present.
    def load_default_files(config)
      default_files = ['default.rb', "#{environment}.rb"]
      default_files << "#{env['MACHINENAME']}.rb" if env['MACHINENAME']

      default_files.each do |file|
        path = File.join(@config_path, file)
        config.load path if File.exist? path
      end

    end
    
  end
  
end