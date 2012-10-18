
module ActiveProfiling
  class Railtie < Rails::Railtie
    # These settings are the default values used when running RubyProf on
    # every request. You can also use the profiler directly by using the
    # ActiveProfiling.ruby_profiler method.
    #
    # * +:enabled+ - Enable profiler on requests.
    # * +:measure_mode+ - The ruby-prof measure mode. The default is
    #   RubyProf::PROCESS_TIME. Use Symbols for this instead of the actual
    #   RubyProf constants (i.e. +:memory+ instead of RubyProf::MEMORY) so
    #   you can have your configuration options in your environment set up
    #   without having to require ruby-prof.
    # * +:disable_gc+ - Whether or not we're disabling garbage collection
    #   during profiling. This is useful when you're profiling memory usage,
    #   where you should disable garbage collection as ruby-prof will
    #   otherwise record information on GC on the method that causes GC rather
    #   than the methods that allocate the memory.
    # * +:printer+ - The RubyProf printer to use. See the RubyProf docs for
    #   details. The default is RubyProf::FlatPrinter. Use Symbols in this
    #   option, i.e. +:flat+ instead of RubyProf::FlatPrinter. (Note that the
    #   FlatPrinterWithLineNumbers printer is called +:flat_with_line_numbers+
    #   here.)
    # * +:call_tree_prefix+ - The prefix to use for +:call_tree+ files. Some
    #   programs like to look for files named "callgrind.out.*", while others
    #   like to look for "cachegrind.out.*".
    # * +:output+ - Where to direct the output from the profiler. If set to
    #   +:stdout+, well, then it's sent to $stdout. When set to +:log+, it
    #   shows up in the log file. When set to +:file+, it gets put in
    #   +Rails.root/log/profiling/+ in a sensible manner. The default depends
    #   on the +:printer+ being used:
    #
    #   * +:file+ - +:graph_html+, +:call_stack+, +:call_tree+, +:dot+
    #   * +:log+ - +:flat+, +:flat_with_line_numbers+, +:graph+ and anything
    #     else
    # * +:log_level+ - The log level to spit the logging information into
    #   when using +:log+ for +:output+. The default is +:info+.
    # * +:printer_options+ - Options to pass to the profiler printer. The
    #   default is:
    #
    #     :printer_options => {
    #       :min_percent => 1,
    #       :print_file => true
    #     }
    DEFAULT_PROFILER_OPTIONS = {
      :enabled => false,

      :measure_mode => :process_time,

      :disable_gc => true,

      :printer => :graph,

      :call_tree_prefix => 'callgrind.out.',

      :output => nil,

      :log_level => :info,

      :printer_options => {
        :min_percent => 1,
        :print_file => true
      }
    }.freeze

    # These settings are the default values used when profiling GC statistics.
    # When enabled, statistics are gathered for every request. You can also
    # gather statistics on a per-block basis using ActiveProfiling.gc_statistics
    # directly.
    #
    # * +:enabled+ - For logging GC stats. Output is dumped into the log on
    #   each request.
    # * +:disable_gc+ - Whether or not we're disabling actual garbage
    #   collection during statistics gathering. If set to true, the garbage
    #   collector will be disabled for the duration of the action and then
    #   re-enabled at the end of the action. This allows you to call GC.start
    #   whenever you need to and see results as you go.
    # * +:log_level+ - The log level to spit the GC statistics to.
    DEFAULT_GC_STATISTICS_OPTIONS = {
      :enabled => false,

      :disable_gc => false,

      :log_level => :info
    }.freeze

    config.active_profiling = ActiveSupport::OrderedOptions.new
    config.active_profiling.profiler = ActiveSupport::OrderedOptions.new
    config.active_profiling.gc_statistics = ActiveSupport::OrderedOptions.new

    initializer "active_profiling.set_profiling_config" do |app|
      options = app.config.active_profiling

      options.profiler.reverse_merge!(DEFAULT_PROFILER_OPTIONS)
      options.gc_statistics.reverse_merge!(DEFAULT_GC_STATISTICS_OPTIONS)
    end
  end
end
