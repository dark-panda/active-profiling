# frozen_string_literal: true

module ActionController
  module ActionProfiling
    extend ActiveSupport::Concern

    included do
      include ActiveProfiling::RubyProfiler
      include ActiveProfiling::GCStatistics

      around_filter_method = if ActionController::Base.respond_to?(:around_action)
        :around_action
      else
        :around_filter
      end

      send around_filter_method, :action_profiler, if: proc {
        Rails.application.config.active_profiling.profiler.enabled && ActiveProfiling.ruby_prof?
      }

      send around_filter_method, :action_gc_statistics, if: proc {
        Rails.application.config.active_profiling.gc_statistics.enabled && ActiveProfiling.gc_statistics?
      }
    end

    def action_profiler(*, &block)
      ruby_profiler(name: "#{controller_name}.#{action_name}", &block)
    end

    def action_gc_statistics(*, &block)
      gc_statistics(&block)
    end
  end

  class Base
    include ActionController::ActionProfiling
  end
end
