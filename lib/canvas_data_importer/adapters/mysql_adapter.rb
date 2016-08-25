module CanvasDataImporter::Adapters
  class MysqlAdapter < AbstractAdapter

    register_adapter 'mysql'

    def initialize(opts = {})
      require 'mysql2'
      super
      @database_port ||= 3306
      @database_host ||= 'localhost'
    end

    def import_data_from_file(table_name, file_path)
      execute_statement("LOAD DATA INFILE '#{file_path}' IGNORE INTO TABLE #{table_name}")
    end

    def import_requests_from_file(schema_definition, file_path)
      build_requests_table(schema_definition)
      temp_table_name = SecureRandom.hex.gsub(/^[0-9]+/, '')
      build_table(schema_definition.merge({ 'tableName' => temp_table_name }))
      import_data_from_file temp_table_name, file_path
      in_transaction do
        execute_statement("DELETE FROM requests USING requests AS requests INNER JOIN #{temp_table_name} AS temp WHERE requests.id = temp.id")
        execute_statement("INSERT INTO requests SELECT #{REQUESTS_COLUMNS.map { |c| "`#{c}`" }.join(', ')} FROM #{temp_table_name}")
      end
      drop_table temp_table_name
    end

    private
    def execute_statement(statement)
      connection.query(statement)
    end

    def establish_connection
      Mysql2::Client.new host: @database_host, port: @database_port, username: @database_username,
        password: @database_password, database: @database_name
    end

    def build_table(definition)
      columns = definition['columns'].map do |column|
        mapping = ["`#{column['name']}`", convert_data_type(column['type'], column['length'])]
        mapping << "(#{column['length']})" if column['length'] && column['type'] != 'varchar'
        if column['name'] == 'id'
          mapping << 'PRIMARY KEY'
        else
          mapping << 'NULL'
        end
        mapping.join(' ')
      end.join(', ')
      execute_statement("CREATE TABLE IF NOT EXISTS #{definition['tableName']} (#{columns})")
    end

    def convert_data_type(data_type, length = nil)
      case data_type
      when 'enum', 'guid'
        'varchar(50)'
      when 'varchar'
        if length.to_i > 256
          'text'
        else
          'varchar(500)'
        end
      when 'boolean'
        'varchar(5)'
      when 'timestamp'
        'datetime'
      else
        data_type
      end
    end
  end
end
