
module ActiveProfiling
  class << self
    def gc_statistics?
      if defined?(@has_gc_statistics)
        @has_gc_statistics
      else
        @has_gc_statistics = defined?(GC::Profiler) || GC.respond_to?(:enable_stats)
      end
    end

    def ruby_prof?
      if defined?(@has_ruby_prof)
        @has_ruby_prof
      else
        @has_ruby_prof = defined?(RubyProf)
      end
    end
  end
end

require 'active-profiling/railtie'
require 'active-profiling/gc_statistics'
require 'active-profiling/ruby_profiler'
require 'active-profiling/action_controller'
require 'active-profiling/active_record'

