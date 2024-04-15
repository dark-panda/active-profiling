# frozen_string_literal: true

module ActiveProfiling::ActiveRecord
  class BacktraceLogSubscriber < ::ActiveSupport::LogSubscriber
    def sql(event)
      return unless skip_backtrace?

      payload = event.payload

      return if payload[:name] == 'SCHEMA'

      backtrace = event.send(:caller).collect { |line|
        "    #{line}" if line_match(line)
      }.compact

      return if backtrace.empty?

      name = color(payload[:name], YELLOW, true)
      logger.send(config.log_level, "  #{name}\n#{backtrace.join("\n")}")
    end

    def logger
      ::ActiveRecord::Base.logger
    end

    private

      def skip_backtrace?
        config.enabled &&
          config.log_level &&
          logger&.send("#{config.log_level}?")
      end

      def config
        Rails.application.config.active_profiling.active_record.backtrace_logger
      end

      def line_match(line)
        config.enabled && (config.verbose || !!(line =~ config.matcher))
      end
  end
end

ActiveProfiling::ActiveRecord::BacktraceLogSubscriber.attach_to :active_record
