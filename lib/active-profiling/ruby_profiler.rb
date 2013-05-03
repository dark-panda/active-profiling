
module ActiveProfiling
  module RubyProfiler
    extend ActiveSupport::Concern

    # Runs a block of Ruby code through ruby-prof and returns the profiler
    # output. Returns an Array containing the the result of the block yielded
    # and the profiler data.
    #
    # For details on the various options, see the default options located in
    # ActiveProfiling::Railtie::DEFAULT_PROFILER_OPTIONS.
    def ruby_profiler(*args)
      options = Rails.application.config.active_profiling.profiler.merge(args.extract_options!)

      printer_class = case options[:printer]
        when :flat_with_line_numbers
          RubyProf::FlatPrinterWithLineNumbers
        else
          RubyProf.const_get("#{options[:printer].to_s.camelize}Printer")
      end

      output = if options[:output]
        options[:output]
      else
        case options[:printer]
          when :call_tree, :call_stack, :graph_html, :dot
            :file
          else
            :log
        end
      end

      return yield if output == :log && !ActiveProfiling::LogSubscriber.logger

      RubyProf.measure_mode = RubyProf.const_get(options[:measure_mode].to_s.upcase)
      GC.disable if options[:disable_gc]

      result = nil
      exception = nil
      profiler_result = RubyProf.profile do
        begin
          result = yield
        rescue
          exception = $!
        end
      end

      case output
        when :stdout
          printer_class.new(profiler_result).print($stdout, options.printer_options)
        when :log
          str = StringIO.new
          printer_class.new(profiler_result).print(str, options.printer_options)
          str.rewind

          ActiveSupport::Notifications.instrument('profiler_output.active_profiling', {
            :profiler_output => str.read,
            :title => options[:title] || args.first
          })
        when :file
          path, file_name = if args.first
            [ File.dirname(args.first), args.first ]
          elsif options[:file_name]
            [ File.dirname(options[:file_name]), options[:file_name] ]
          else
            time = Time.now.strftime('%Y-%m-%d-%H:%M:%S')
            hash = Digest::MD5.hexdigest(rand.to_s)[0..6]
            path = Rails.root.join('log/profiling', self.class.name.underscore)
            ext = case options[:printer]
              when :graph_html, :call_stack
                'html'
              when :dot
                'dot'
              else
                'log'
            end

            file_name = [
              self.action_name,
              options[:measure_mode],
              options[:printer],
              time,
              hash,
              ext
            ].join('.')

            if options[:printer] == :call_tree && !options[:call_tree_prefix].blank?
              file_name = "#{options[:call_tree_prefix]}#{file_name}"
            end

            [ path.to_s, path.join(file_name) ]
          end

          ActiveSupport::Notifications.instrument('profiler_output_to_file.active_profiling', {
            :file_name => file_name
          })

          FileUtils.mkdir_p(path)
          printer_class.new(profiler_result).print(File.open(file_name, 'w'), options[:printer_options])
      end

      if exception
        raise exception
      else
        result
      end
    ensure
      GC.enable if options[:disable_gc]
    end
  end

  self.extend(RubyProfiler)
end
