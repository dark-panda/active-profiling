
module ActiveProfiling
  module RubyProfiler
    extend ActiveSupport::Concern

    # Runs a block of Ruby code through ruby-prof and returns the profiler
    # output. Returns an Array containing the the result of the block yielded
    # and the profiler data.
    #
    # Options:
    #
    # * :measure_mode - set the measure mode on RubyProf. The default is
    #   RubyProf::PROCESS_TIME.
    # * :disable_gc - temporarily disable the garbage collector for the
    #   duration of the profiling session. The default is false.
    def ruby_profiler(options = {})
      return [ yield, nil ] unless defined?(RubyProf)

      options = {
        :measure_mode => RubyProf::PROCESS_TIME,
        :disable_gc => false
      }.merge options

      RubyProf.measure_mode = options[:measure_mode]
      GC.disable if options[:disable_gc]

      retval = nil
      profile = RubyProf.profile do
        retval = yield
      end

      return [ retval, profile ]

    ensure
      GC.enable if options[:disable_gc]
    end
  end

  self.extend(RubyProfiler)
end
