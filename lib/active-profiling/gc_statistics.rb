
module ActiveProfiling
  module GCStatistics
    extend ActiveSupport::Concern

    if defined?(GC::Profiler)
      # Profiles a block, capturing information on the garbage collector. The
      # return value is an Array containing the result of the yielded block
      # and a String with a report on the profiling results.
      #
      # Options:
      #
      # * :disable_gc - disables garbage collection for the duration of the
      #   block and then renables it immediately afterwards and runs GC.start.
      #   This ensures that GC is run at least once for the block so that you
      #   can see what the block itself is doing. If you want to leave GC
      #   running on its own without any interference, set this value to false.
      #   The default value is false.
      #
      # This method only works with versions of Ruby that implement
      # GC::Profiler or that have been patched to implement some additional
      # garbage collection statistics. In older versions, such as version
      # 1.8.7, you can either use Ruby Enterprise Edition or patch your build
      # with the GC statistics patch found here:
      #
      # http://blog.pluron.com/2008/02/memory-profilin.html
      def gc_statistics(options = {})
        options = {
          :disable_gc => false
        }.merge(options)

        GC.disable if options[:disable_gc]
        GC::Profiler.enable
        GC::Profiler.clear

        retval = yield

        if options[:disable_gc]
          GC.enable
          GC.start
        end

        result = GC::Profiler.result

        return [ retval, result ]

      ensure
        GC.enable if options[:disable_gc]
        GC::Profiler.disable
        GC::Profiler.clear
      end
    elsif GC.respond_to?(:enable_stats)
      def gc_statistics(options = {})
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

      def gc_statistics(*args)
        [ yield, nil ]
      end
    end
  end

  self.extend(GCStatistics)
end
