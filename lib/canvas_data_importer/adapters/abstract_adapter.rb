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

    private
    def establish_connection
      raise 'must be overridden in a sub class'
    end
  end
end
