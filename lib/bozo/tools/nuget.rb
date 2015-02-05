require 'open-uri'

module Bozo::Tools
  class Nuget

    # Creates a new instance.
    def initialize
      @url = 'http://download-codeplex.sec.s-msft.com/Download/Release?ProjectName=nuget&DownloadId=697144&FileTime=130190897355830000&Build=20959'
    end

    # Sets the source url for the nuget tool to be retreived from
    #
    # @param [String] url
    #     A web server hosting the nuget tool
    def source(url)
      @url = url
    end

    # Retreives the nuget tool exe from the path
    def retrieve(destination_path)
      open(File.join(destination_path, 'nuget.exe'), 'wb') do |file|
        file << open(@url).read
      end
    end
  end
end
