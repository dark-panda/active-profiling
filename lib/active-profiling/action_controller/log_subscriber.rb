# frozen_string_literal: true

module ActiveProfiling::ActionController
  class LogSubscriber < ActiveSupport::LogSubscriber
    def profiler_output(event)
      return unless logger&.send("#{config.profiler.log_level}?")

      report = indent(event.payload[:profiler_output])
      title = event.payload[:title]

      logger.send(
        config.profiler.log_level,
        "#{color("Profiler Output: #{title}", YELLOW, bold: true)}\n#{report}"
      )
    end

    def profiler_output_to_file(event)
      return unless logger&.send("#{config.profiler.log_level}?")

      logger.send(
        config.profiler.log_level,
        color("Wrote profiling information to #{event.payload[:file_name]}", YELLOW, bold: true)
      )
    end

    def gc_statistics(event)
      return unless logger&.send("#{config.gc_statistics.log_level}?")

      return if event.payload[:report].blank?

      title = event.payload[:title]
      report = indent(event.payload[:report])

      logger.send(
        config.gc_statistics.log_level,
        "#{color("GC Statistics: #{title}", YELLOW, bold: true)}\n#{report}"
      )
    end

    def logger
      ::Rails.logger
    end

    private

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
