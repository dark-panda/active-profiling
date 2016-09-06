
module ActiveProfiling
  module RubyProfiler
    class Output
      def initialize(*args)
        @options = Rails.application.config.active_profiling.profiler.merge(args.extract_options!)
        @path = args.first

        @output = if @options[:output]
          @options[:output]
        else
          case @options[:printer]
            when :call_tree, :call_stack, :graph_html, :dot
              :file
            else
              :log
          end
        end
      end

      def run
        return yield if @output == :log && !ActiveProfiling::ActionController::LogSubscriber.logger

        RubyProf.measure_mode = RubyProf.const_get(@options[:measure_mode].to_s.upcase)
        GC.disable if @options[:disable_gc]

        result = nil
        exception = nil
        @profiler_result = RubyProf.profile do
          begin
            result = yield
          rescue
            exception = $!
          end
        end

        case @output
          when :stdout
            write_to_stdout
          when :log
            write_to_log
          when :file
            write_to_file_or_path
        end

        if exception
          raise exception
        else
          result
        end
      ensure
        GC.enable if @options[:disable_gc]
      end

      private

      def printer_class
        @printer_class ||= case @options[:printer]
          when :flat_with_line_numbers
            RubyProf::FlatPrinterWithLineNumbers
          else
            RubyProf.const_get("#{@options[:printer].to_s.camelize}Printer")
        end
      end

      def path_and_file_name
        return @path_and_file_name if defined?(@path_and_file_name)

        if @path.present?
          { path: File.dirname(@path), file_name: @path }
        elsif @options[:file_name]
          { path: File.dirname(options[:file_name]), file_name: @options[:file_name] }
        else
          time = Time.now.strftime('%Y-%m-%d-%H:%M:%S')
          hash = Digest::MD5.hexdigest(rand.to_s)[0..6]
          path = Rails.root.join('log/profiling')
          ext = case @options[:printer]
            when :graph_html, :call_stack
              'html'
            when :dot
              'dot'
            else
              'log'
          end

          file_name = [
            @options[:name],
            @options[:measure_mode],
            @options[:printer],
            time,
            hash,
            ext
          ].join('.')

          @path_and_file_name = {
            path: path.to_s,
            file_name: path.join(file_name)
          }
        end
      end

      def write_to_stdout
        printer_class.new(@profiler_result).print($stdout, @options)
      end

      def write_to_log
        str = StringIO.new
        printer_class.new(@profiler_result).print(str, @options[:printer_options])
        str.rewind

        ActiveSupport::Notifications.instrument('profiler_output.active_profiling', {
          :profiler_output => str.read,
          :title => @options[:title] || @path
        })
      end

      def write_to_file_or_path
        if call_tree_printer_file_output?
          write_to_path
        else
          write_to_file
        end
      end

      def write_to_file
        ActiveSupport::Notifications.instrument('profiler_output_to_file.active_profiling', {
          :file_name => path_and_file_name[:file_name]
        })

        FileUtils.mkdir_p(path_and_file_name[:path])
        printer_class.new(@profiler_result).print(File.open(path_and_file_name[:file_name], 'w'), @options[:printer_options])
      end

      def write_to_path
        ActiveSupport::Notifications.instrument('profiler_output_to_file.active_profiling', {
          :file_name => path_and_file_name[:path]
        })

        FileUtils.mkdir_p(path_and_file_name[:path])
        printer_class.new(@profiler_result).print(merged_printer_options(path_and_file_name))
      end

      def call_tree_prefix_option
        # XXX - Bit of a hack here -- newer versions of RubyProf have changed
        # the method signature of CallTreePrinter#print and changed how the
        # generated files are prefixed. To accomodate call tree viewers like
        # [KQ]CacheGrind, we need to hack in an appropriate file prefix.
        if call_tree_printer_file_output?
          @options[:call_tree_prefix].try(:gsub, /\.$/, '')
        else
          @options[:call_tree_prefix]
        end
      end

      def merged_printer_options(path_and_file_name)
        if @options[:printer] == :call_tree && @output == :file
          @options[:printer_options].merge(
            profile: call_tree_prefix_option,
            path: path_and_file_name[:path]
          )
        else
          @options[:printer_options]
        end
      end

      def call_tree_printer_file_output?
        printer_class.instance_method(:print).arity == -1 && printer_class == RubyProf::CallTreePrinter
      end
    end
  end
end
