
module ActiveProfiling
  class LogSubscriber < ActiveSupport::LogSubscriber
    def profiler_output(event)
      return unless logger &&
        logger.send("#{config.profiler_log_level}?")

      report = self.indent(event.payload[:profiler_output])

      logger.send(
        config.profiler_log_level,
        "#{color("Profiler Output", YELLOW, true)}\n#{report}"
      )
    end

    def profiler_output_to_file(event)
      return unless logger &&
        logger.send("#{config.profiler_log_level}?")

      logger.send(
        config.profiler_log_level,
        color("Wrote profiling information to #{event.payload[:file_name]}", YELLOW, true)
      )
    end

    def gc_profiler(event)
      return unless logger &&
        logger.send("#{config.profiler_log_level}?")

      unless event.payload[:report].blank?
        report = self.indent(event.payload[:report])

        logger.send(
          config.gc_statistics_log_level,
          "#{color('GC Statistics', YELLOW, true)}\n#{report}"
        )
      end
    end

    def logger
      ::Rails.logger
    end

    protected
      def config
        Rails.application.config.active_profiling
      end

      def indent(text)
        text.split("\n").collect { |line|
          "  #{line}"
        }.join("\n")
      end
  end
end

ActiveProfiling::LogSubscriber.attach_to :active_profiling
