
module ActiveProfiling::ActiveRecord
  class BacktraceLogSubscriber < ::ActiveSupport::LogSubscriber
    def sql(event)
      return unless config.log_level &&
        logger &&
        logger.send("#{config.log_level}?")

      payload = event.payload

      return if 'SCHEMA' == payload[:name]

      backtrace = event.send(:caller).collect { |line|
        if line_match(line)
          "    #{line}"
        end
      }.compact

      unless backtrace.empty?
        name = color(payload[:name], YELLOW, true)
        logger.send(config.log_level, "  #{name}\n#{backtrace.join("\n")}")
      end
    end

    def logger
      ::ActiveRecord::Base.logger
    end

    protected
      def config
        Rails.application.config.active_profiling.active_record.backtrace_logger
      end

      def line_match(line)
        config.enabled && (config.verbose || !!(line =~ config.matcher))
      end
  end
end

ActiveProfiling::ActiveRecord::BacktraceLogSubscriber.attach_to :active_record

