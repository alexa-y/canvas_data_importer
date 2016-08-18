module CanvasDataImporter::Helpers
  module Sanitizer

    def escape_and_encode_file(file_path)
      temp_file = File.open("#{file_path}.tmp", 'w')

      File.open(file_path).each_line do |line|
        temp_file << line.gsub(/(?!\\N)\\/, "\\\\\\\\")
      end
      FileUtils.cp temp_file, file_path
    end
  end

end
