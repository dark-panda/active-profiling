
require 'digest/md5'

module ActionController
  module ActionProfiling
    extend ActiveSupport::Concern

    included do
      include ActiveProfiling::RubyProfiler
      include ActiveProfiling::GCStatistics

      around_filter :action_profiler, :if => proc {
        Rails.application.config.active_profiling.profiler_enabled
      }

      around_filter :action_gc_profiler, :if => proc {
        Rails.application.config.active_profiling.gc_statistics_enabled
      }
    end

    def action_profiler(*args)
      profiling_config = Rails.application.config.active_profiling

      return yield if !profiling_config.profiler_enabled || !ActiveProfiling.ruby_prof?

      printer_class = RubyProf.const_get("#{profiling_config.profiler_printer.to_s.camelize}Printer")

      output = if profiling_config.profiler_output
        profiling_config.profiler_output
      elsif [ RubyProf::CallTreePrinter, RubyProf::GraphHtmlPrinter ].include?(printer_class)
        :file
      else
        :log
      end

      return yield if output == :log && !ActiveProfiling::LogSubscriber.logger

      result, profiler_result = ruby_profiler(
        :measure_mode => RubyProf.const_get(profiling_config.profiler_measure_mode.to_s.upcase),
        :disable_gc => profiling_config.profiler_disable_gc
      ) do
        yield
      end

      case output
        when :stdout
          printer_class.new(profiler_result).print($stdout, profiling_config.profiler_printer_options)
        when :log
          str = StringIO.new
          printer_class.new(profiler_result).print(str, profiling_config.profiler_printer_options)
          str.rewind

          ActiveSupport::Notifications.instrument('profiler_output.active_profiling', {
            :profiler_output => str.read
          })
        when :file
          time = Time.now.strftime('%Y-%m-%d-%H:%M:%S')
          hash = Digest::MD5.hexdigest(rand.to_s)[0..6]
          path = Rails.root.join('log/profiling', self.class.name.underscore)

          FileUtils.mkdir_p(path)

          file_name = if profiling_config.profiler_printer == :call_tree
            path.join([
              'callgrind.out',
              self.action_name,
              profiling_config.profiler_measure_mode,
              profiling_config.profiler_printer,
              time,
              hash
            ].join('.'))
          else
            path.join([
              self.action_name,
              profiling_config.profiler_measure_mode,
              profiling_config.profiler_printer,
              time,
              hash,
              profiling_config.profiler_printer == :graph_html ? 'html' : 'log'
            ].join('.'))
          end

          ActiveSupport::Notifications.instrument('profiler_output_to_file.active_profiling', {
            :file_name => file_name
          })

          printer_class.new(profiler_result).print(File.open(file_name, 'w'), profiling_config.profiler_printer_options)
      end

      result
    end

    def action_gc_profiler(*args)
      profiling_config = Rails.application.config.active_profiling

      return yield if !profiling_config.gc_statistics_enabled || !ActiveProfiling.gc_statistics?

      result, gc_report = gc_statistics(:disable_gc => profiling_config.gc_statistics_disable_gc) do
        yield
      end

      ActiveSupport::Notifications.instrument('gc_profiler.active_profiling', {
        :report => gc_report
      })

      result
    end
  end

  class Base
    include ActionController::ActionProfiling
  end
end
