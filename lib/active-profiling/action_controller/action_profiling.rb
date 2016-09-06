
module ActionController
  module ActionProfiling
    extend ActiveSupport::Concern

    included do
      include ActiveProfiling::RubyProfiler
      include ActiveProfiling::GCStatistics

      around_filter :action_profiler, :if => proc {
        Rails.application.config.active_profiling.profiler.enabled && ActiveProfiling.ruby_prof?
      }

      around_filter :action_gc_statistics, :if => proc {
        Rails.application.config.active_profiling.gc_statistics.enabled && ActiveProfiling.gc_statistics?
      }
    end

    def action_profiler(*args)
      ruby_profiler(:name => "#{controller_name}.#{action_name}") do
        yield
      end
    end

    def action_gc_statistics(*args)
      gc_statistics do
        yield
      end
    end
  end

  class Base
    include ActionController::ActionProfiling
  end
end
