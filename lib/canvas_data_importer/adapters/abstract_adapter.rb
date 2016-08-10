module CanvasDataImporter::Adapters
  class AbstractAdapter
    REQUESTS_COLUMNS = ["id", "timestamp", "timestamp_year", "timestamp_month", "timestamp_day", "user_id", "course_id",
      "root_account_id", "course_account_id", "quiz_id", "discussion_id", "conversation_id", "assignment_id", "url", "user_agent",
      "http_method", "remote_ip", "interaction_micros", "web_application_controller", "web_applicaiton_action",
      "web_application_context_type", "web_application_context_id", "real_user_id", "session_id", "user_agent_id",
      "http_status", "http_version"].freeze

    @@adapter_types = {}

    def self.register_adapter(val)
      @@adapter_types[val] = self
      @adapter_type = val
    end

    def self.for_adapter_type(val)
      @@adapter_types[val]
    end

    def self.connect(opts = {})
      adapter = self.new(opts)
      adapter.connection
      adapter
    end

    def initialize(opts = {})
      opts.each do |k, v|
        instance_variable_set "@#{k.to_s}", v
      end
    end

    def connection
      @connection ||= establish_connection
    end

    def build_tables(schema_definition)
      definition = schema_definition.dup
      definition.delete 'requests'
      definition.each do |k, v|
        drop_table v['tableName']
        build_table v
      end
    end

    def import_requests_from_file(schema_definition, file_path)
      build_requests_table(schema_definition)
      temp_table_name = SecureRandom.hex.gsub(/^[0-9]+/, '')
      build_table(schema_definition.merge({ 'tableName' => temp_table_name }))
      import_data_from_file temp_table_name, file_path
      in_transaction do
        execute_statement("DELETE FROM requests USING #{temp_table_name} WHERE requests.id = #{temp_table_name}.id")
        execute_statement("INSERT INTO requests SELECT #{REQUESTS_COLUMNS.map { |c| "\"#{c}\"" }.join(', ')} FROM #{temp_table_name}")
      end
      drop_table temp_table_name
    end

    private
    def in_transaction
      yield if block_given?
    end

    def establish_connection
      raise 'must be overridden in a sub class'
    end

    def drop_table(table_name)
      execute_statement("DROP TABLE IF EXISTS #{table_name}")
    end

    def build_requests_table(definition)
      sanitized_definition = definition.dup
      sanitized_definition['columns'].select! { |c| REQUESTS_COLUMNS.include?(c['name']) }
      build_table(sanitized_definition)
    end
  end
end
