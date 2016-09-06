
require 'active-profiling/ruby_profiler/output'

module ActiveProfiling
  module RubyProfiler
    extend ActiveSupport::Concern

    # Runs a block of Ruby code through ruby-prof and returns the profiler
    # output. Returns an Array containing the the result of the block yielded
    # and the profiler data.
    #
    # For details on the various options, see the default options located in
    # ActiveProfiling::Railtie::DEFAULT_PROFILER_OPTIONS.
    def ruby_profiler(*args, &block)
      Output.new(*args).run(&block)
    end
  end

  self.extend(RubyProfiler)
end
