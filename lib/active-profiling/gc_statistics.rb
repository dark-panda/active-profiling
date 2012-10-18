
module ActiveProfiling
  module GCStatistics
    extend ActiveSupport::Concern

    if defined?(GC::Profiler)
      def gc_statistics_report(options = {})
        options = {
          :disable_gc => false
        }.merge(options)

        GC.disable if options[:disable_gc]
        GC::Profiler.enable
        GC::Profiler.clear

        retval = yield

        if options[:disable_gc]
          GC.enable
        end

        result = GC::Profiler.result

        return [ retval, result ]

      ensure
        GC.enable if options[:disable_gc]
        GC::Profiler.disable
        GC::Profiler.clear
      end
    elsif GC.respond_to?(:enable_stats)
      def gc_statistics_report(options = {})
        options = {
          :disable_gc => false
        }.merge(options)

        GC.disable if options[:disable_gc]
        GC.enable_stats
        GC.clear_stats

        retval = yield

        result = [
          "Allocated size: #{GC.allocated_size}",
          "Number of allocations: #{GC.num_allocations}",
          "Collections: #{GC.collections}",
          "Time (ms): #{GC.time / 1000.0}"
        ].join("\n")

        return [ retval, result ]

      ensure
        GC.enable if options[:disable_gc]
        GC.disable_stats
        GC.clear_stats
      end
    else
      $stderr.puts "NOTICE: this version of Ruby cannot report on GC statistics."

      def gc_statistics_report(*args)
        [ yield, nil ]
      end
    end

    private :gc_statistics_report

    # Profiles a block, capturing information on the garbage collector. The
    # return value is an Array containing the result of the yielded block
    # and a String with a report on the profiling results.
    #
    # Options:
    #
    # * +:disable_gc+ - disables garbage collection for the duration of the
    #   block and then renables it immediately afterwards. This allows you to
    #   control when GC is run and see the results.
    # * +:title+ - a title to use for logging.
    #
    # More options for this method can be found in the default settings,
    # located in ActiveProfiling::Railtie::DEFAULT_GC_STATISTICS_OPTIONS.
    #
    # This method only works with versions of Ruby that implement
    # GC::Profiler or that have been patched to implement some additional
    # garbage collection statistics. In older versions, such as version
    # 1.8.7, you can either use Ruby Enterprise Edition or patch your build
    # with the GC statistics patch found here:
    #
    # http://blog.pluron.com/2008/02/memory-profilin.html
    def gc_statistics(*args)
      options = Rails.application.config.active_profiling.gc_statistics.merge(args.extract_options!)

      result, gc_report = gc_statistics_report(options) do
        yield
      end

      ActiveSupport::Notifications.instrument('gc_statistics.active_profiling', {
        :report => gc_report,
        :title => options[:title] || args.first
      })

      result
    end
  end

  self.extend(GCStatistics)
end
