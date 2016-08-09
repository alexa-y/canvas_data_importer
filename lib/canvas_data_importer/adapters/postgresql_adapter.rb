module CanvasDataImporter::Adapters
  class PostgresqlAdapter < AbstractAdapter
    require 'pg'

    register_adapter 'postgres'
    register_adapter 'pg'
    register_adapter 'postgresql'

    def initialize(opts = {})
      super
      @database_port ||= 5432
      @database_host ||= 'localhost'
    end

    def build_tables(schema_definition)
      definition = schema_definition.dup
      definition.delete 'requests'
      definition.each do |k, v|
        drop_table v['tableName']
        build_table v
      end
    end

    def import_data_from_file(table_name, file_path)
      connection.exec("COPY #{table_name} FROM '#{file_path}'")
    end

    def import_requests_from_file(schema_definition, file_path)
      build_requests_table(schema_definition)
      temp_table_name = SecureRandom.hex.gsub(/^[0-9]+/, '')
      build_table(schema_definition.merge({ 'tableName' => temp_table_name }))
      import_data_from_file temp_table_name, file_path
      connection.transaction do
        connection.exec("DELETE FROM requests USING #{temp_table_name} WHERE requests.id = #{temp_table_name}.id")
        connection.exec("INSERT INTO requests SELECT #{REQUESTS_COLUMNS.map { |c| "\"#{c}\"" }.join(', ')} FROM #{temp_table_name}")
      end
      drop_table temp_table_name
    end

    private
    def establish_connection
      pg = PG::Connection.new host: @database_host, port: @database_port, user: @database_username,
        password: @database_password, dbname: @database_name
      if @database_schema
        pg.exec("SET search_path TO #{@database_schema}")
      end
      pg
    end

    def drop_table(table_name)
      connection.exec("DROP TABLE IF EXISTS #{table_name}")
    end

    def build_table(definition)
      columns = definition['columns'].map do |column|
        mapping = ["\"#{column['name']}\"", convert_data_type(column['type'])]
        mapping << "(#{column['length']})" if column['length'] && column['type'] != 'varchar'
        mapping.join(' ')
      end.join(', ')
      connection.exec("CREATE TABLE IF NOT EXISTS #{definition['tableName']} (#{columns})")
    end

    def build_requests_table(definition)
      sanitized_definition = definition.dup
      sanitized_definition['columns'].select! { |c| REQUESTS_COLUMNS.include?(c['name']) }
      build_table(sanitized_definition)
    end

    def convert_data_type(data_type)
      case data_type
      when 'guid'
        'uuid'
      when 'enum'
        'varchar(50)'
      when 'varchar'
        'varchar(65535)'
      when 'datetime'
        'timestamp'
      else
        data_type
      end
    end

  end
end
