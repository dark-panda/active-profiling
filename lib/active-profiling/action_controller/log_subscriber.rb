
module ActiveProfiling::ActionController
  class LogSubscriber < ActiveSupport::LogSubscriber
    def profiler_output(event)
      return unless logger &&
        logger.send("#{config.profiler.log_level}?")

      report = self.indent(event.payload[:profiler_output])
      title = event.payload[:title]

      logger.send(
        config.profiler.log_level,
        "#{color("Profiler Output: #{title}", YELLOW, true)}\n#{report}"
      )
    end

    def profiler_output_to_file(event)
      return unless logger &&
        logger.send("#{config.profiler.log_level}?")

      logger.send(
        config.profiler.log_level,
        color("Wrote profiling information to #{event.payload[:file_name]}", YELLOW, true)
      )
    end

    def gc_statistics(event)
      return unless logger &&
        logger.send("#{config.gc_statistics.log_level}?")

      unless event.payload[:report].blank?
        title = event.payload[:title]
        report = self.indent(event.payload[:report])

        logger.send(
          config.gc_statistics.log_level,
          "#{color("GC Statistics: #{title}", YELLOW, true)}\n#{report}"
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

ActiveProfiling::ActionController::LogSubscriber.attach_to :active_profiling
