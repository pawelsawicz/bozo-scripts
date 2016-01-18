require 'open-uri'
require 'zip/zipfilesystem'

module Bozo::Tools
  class OctopusTools

    # Creates a new instance.
    def initialize
      @url = 'https://download.octopusdeploy.com/octopus-tools/3.3.2/OctopusTools.3.3.2.zip'
    end

    # Sets the source url for the Octopus Tools to be retrieved from
    #
    # @param [String] url
    #     A web server hosting the Octopus Tools
    def source(url)
      @url = url
    end

    # Retrieves the Octopus tools exe from the path
    def retrieve(destination_path)
      zip_file_path = download_path('OctopusTools.3.3.2.zip')

      open(zip_file_path, 'wb') do |file|
        file << open(@url).read
      end

      extract_zip(zip_file_path, destination_path)
    end

    private
    def extract_zip(source, destination_path)
      Zip::ZipFile.open(source) do |zip_file|
        zip_file.each { |f|
          f_path = File.join(destination_path, f.name)
          FileUtils.mkdir_p(File.dirname(f_path))
          zip_file.extract(f, f_path) unless File.exist?(f_path)
        }
      end
    end

    def download_path(source_name)
      FileUtils.mkdir_p('temp')
      File.join('temp', source_name)
    end
  end
end
