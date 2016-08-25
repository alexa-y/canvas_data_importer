module CanvasDataImporter::Adapters
  class PostgresqlAdapter < AbstractAdapter
    register_adapter 'postgres'
    register_adapter 'pg'
    register_adapter 'postgresql'

    def initialize(opts = {})
      require 'pg'
      super
      @database_port ||= 5432
      @database_host ||= 'localhost'
    end

    def import_data_from_file(table_name, file_path)
      execute_statement("COPY #{table_name} FROM '#{file_path}'")
    end

    private
    def in_transaction
      connection.transaction do
        yield if block_given?
      end
    end

    def execute_statement(statement)
      connection.exec(statement)
    end

    def establish_connection
      pg = PG::Connection.new host: @database_host, port: @database_port, user: @database_username,
        password: @database_password, dbname: @database_name
      if @database_schema
        pg.exec("SET search_path TO #{@database_schema}")
      end
      pg
    end

    def build_table(definition)
      columns = definition['columns'].map do |column|
        mapping = ["\"#{column['name']}\"", convert_data_type(column['type'])]
        mapping << "(#{column['length']})" if column['length'] && column['type'] != 'varchar'
        mapping.join(' ')
      end.join(', ')
      execute_statement("CREATE TABLE IF NOT EXISTS #{definition['tableName']} (#{columns})")
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
