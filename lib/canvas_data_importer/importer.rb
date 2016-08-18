require 'canvas_data_client'
require 'byebug'

module CanvasDataImporter
  class Importer
    include CanvasDataImporter::Helpers::Sanitizer

    attr_accessor :opts, :canvas_data_client, :adapter

    def initialize(opts = {})
      @opts = opts
      @opts[:dump] ||= 'latest'
      @opts[:database_type] ||= 'pg'
      @canvas_data_client = CanvasDataClient::Client.new(@opts[:canvas_data_key], @opts[:canvas_data_secret])
      @adapter = CanvasDataImporter::Adapters::AbstractAdapter.for_adapter_type(@opts[:database_type]).connect(@opts)
      @logger = Logger.new(STDOUT)
    end

    def import(dump = @opts[:dump])
      dump_definition = get_dump_definition(dump)
      schema_definition = @canvas_data_client.schema(dump_definition['schemaVersion'])
      Dir.mktmpdir do |dir|
        requests_files = dump_definition['artifactsByTable'].delete 'requests'
        unless @opts[:data_only]
          requests_files['files'].each do |file_mapping|
            @logger.info "Downloading and importing requests file #{file_mapping['filename']}"
            file_path = @canvas_data_client.send(:download_raw_file, file_mapping, dir)
            escape_and_encode_file(file_path)
            @adapter.import_requests_from_file(schema_definition['schema']['requests'], file_path)
          end
        end

        unless @opts[:requests_only]
          @adapter.build_tables(schema_definition['schema'])
          dump_definition['artifactsByTable'].each do |k, v|
            table_name = v['tableName']
            @logger.info "Downloading and importing into #{table_name}"
            v['files'].each do |file_mapping|
              file_path = @canvas_data_client.send(:download_raw_file, file_mapping, dir)
              escape_and_encode_file(file_path)
              @adapter.import_data_from_file(table_name, file_path)
            end
          end
        end
      end
    end

    private
    def get_dump_definition(dump)
      if dump == 'latest'
        @canvas_data_client.latest
      else
        @canvas_data_client.dump(dump)
      end
    end
  end
end
