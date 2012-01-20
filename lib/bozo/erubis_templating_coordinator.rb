require 'erubis'

module Bozo
  
  # Class for creating files based upon configuration files and ERB-style
  # templates.
  # 
  # == Overview
  # 
  # This class is primarily intended for generating config files with shared
  # values but it is capable of generating whatever files you want.
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
  class ErubisTemplatingCoordinator

    # Create a new instance.
    #
    # @param [Configuration] configuration
    #     The configuration to use with templates. If not specified a new
    #     object is created.
    def initialize(configuration = Bozo::Configuration.new)
      @templates = []
      @configuration = configuration
    end

    # Adds a required configuration file to the underlying configuration
    # object.
    # 
    # @param [String] path
    #     The path of the configuration file to load.
    def required_config_file(path)
      raise RuntimeError.new "Required config file #{path} could not be found" unless File.exist? path
      config_file path
    end
    
    # Adds a configuration file to the underlying configuration object if a
    # file exists at the given path.
    # 
    # @param [String] path
    #     The path of the configuration file to load.
    def config_file(path)
      @configuration.load path if File.exist? path
    end

    # Adds a template file to use when generating files.
    # 
    # @param [String] path
    #     The path of the template file.
    def template_file(path)
      @templates << path
    end

    # Adds a selection of template files to use when generating files.
    # 
    # @param [String] glob
    #     A glob from that matches template files.
    def template_files(glob)
      @templates = @templates + Dir[glob]
    end

    # Generate all the files matching the underlying configuration.
    #
    # @param [Proc] block
    #     A block that will be called with the template path and target file
    #     path when provided.
    def generate_files(&block)
      @templates.each {|template| generate_file template, block}
    end

    private

    # Generate the file relating to the template file using the given
    # configuration.
    # 
    # @param [String] template_path
    #     The path of the template file that should be filled using the
    #     configuration.
    # @param [Proc] block
    #     A block that will be called with the template path and target file
    #     path when provided.
    def generate_file(template_path, block)
      target_path = template_path.sub /\.[^\.]+$/, ''

      block.call(template_path, target_path) unless block.nil?

      template_content = IO.read template_path
      template = Erubis::Eruby.new template_content

      content = @configuration.apply {|binding| template.result(binding)}

      File.open(target_path, 'w+') {|f| f.write(content)}
    end

  end

end