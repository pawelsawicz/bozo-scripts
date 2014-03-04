require 'open-uri'

module Bozo::Tools

  class Nuget

    def retrieve(destination_path)
      open(File.join(destination_path, 'nuget.exe'), 'wb') do |file|
        file << open('http://download-codeplex.sec.s-msft.com/Download/Release?ProjectName=nuget&DownloadId=697144&FileTime=130190897355830000&Build=20669').read
      end
    end

  end

end