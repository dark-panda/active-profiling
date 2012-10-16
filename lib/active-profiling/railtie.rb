
module ActiveProfiling
  class Railtie < Rails::Railtie
    DEFAULT_OPTIONS = {
      # For logging GC stats. Output is dumped into the log on each request.
      :gc_statistics_enabled => false,

      # Whether or not we're disabling actual garbage collection during
      # statistics gathering. If set to true, the garbage collector will
      # be disabled for the duration of the action and then re-enabled
      # at the end of the action and a round of garbage collection will be
      # forced. This allows you to see what the action itself costs in terms
      # of GC and objects allocated and the like.
      :gc_statistics_disable_gc => false,

      # THe log level to spit the GC statistics to.
      :gc_statistics_log_level => :info,

      # Enable profiler on requests.
      :profiler_enabled => false,

      # The ruby-prof measure mode. The default is RubyProf::PROCESS_TIME.
      # Use Symbols for this instead of the actual RubyProf constants (i.e.
      # :memory instead of RubyProf::MEMORY) so you can have your
      # configuration options in your environment set up without having to
      # require ruby-prof.
      :profiler_measure_mode => :process_time,

      # Whether or not we're disabling garbage collection during profiling.
      # This is useful when you're profiling memory usage, where you should
      # disable garbage collection as ruby-prof will otherwise record
      # information on GC on the method that causes GC rather than the
      # methods that allocate the memory.
      :profiler_disable_gc => true,

      # The ruby-prof printer to use. See the ruby-prof docs for details.
      # The default is RubyProf::FlatPrinter. Use Symbols in this option,
      # i.e. :flat instead of RubyProf::FlatPrinter. (Note that the
      # FlatPrinterWithLineNumbers printer is called :flat_with_line_numbers
      # here.)
      :profiler_printer => :graph,

      # Where to direct the output from the profiler. If set to :stdout,
      # well, then it's sent to $stdout. When set to :log, it shows up in
      # the log file. When set to :file, it gets put in log/profiling/ in a
      # sensible manner. The default is :log for FlatPrinter and GraphPrinter
      # and :file for GraphHtmlPrinter and CallTreePrinter.
      :profiler_output => nil,

      # The log level to spit the logging information into when using :log
      # for profiler_output. The default is :info.
      :profiler_log_level => :info,

      # Options to pass to the profiler printer.
      :profiler_printer_options => {
        :min_percent => 1,
        :print_file => true
      }
    }.freeze

    config.active_profiling = ActiveSupport::OrderedOptions.new

    initializer "active_profiling.set_profiling_config" do |app|
      options = app.config.active_profiling

      options.reverse_merge!(DEFAULT_OPTIONS)
    end
  end
end
