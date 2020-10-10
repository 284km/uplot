# frozen_string_literal: true

require 'optparse'
require_relative 'params'

module Uplot
  class Command
    class Parser
      attr_reader :command, :params,
                  :delimiter, :transpose, :headers, :pass, :output, :fmt, :debug

      def initialize
        @command = nil
        @params = Params.new

        @delimiter  = "\t"
        @transpose  = false
        @headers    = nil
        @pass       = false
        @output     = $stderr
        @fmt        = 'xyy'
        @debug      = false
      end

      def create_default_parser
        OptionParser.new do |opt|
          opt.program_name = 'uplot'
          opt.version = Uplot::VERSION
          opt.on('-O', '--pass [VAL]', 'file to output standard input data to [stdout]') do |v|
            @pass = v || $stdout
          end
          opt.on('-o', '--output VAL', 'file to output results to [stderr]') do |v|
            @output = v
          end
          opt.on('-d', '--delimiter VAL', 'use DELIM instead of TAB for field delimiter', String) do |v|
            @delimiter = v
          end
          opt.on('-H', '--headers', 'specify that the input has header row', TrueClass) do |v|
            @headers = v
          end
          opt.on('-T', '--transpose', TrueClass) do |v|
            @transpose = v
          end
          opt.on('-t', '--title VAL', 'print string on the top of plot', String) do |v|
            params.title = v
          end
          opt.on('-x', '--xlabel VAL', 'print string on the bottom of the plot', String) do |v|
            params.xlabel = v
          end
          opt.on('-y', '--ylabel VAL', 'print string on the far left of the plot', String) do |v|
            params.ylabel = v
          end
          opt.on('-w', '--width VAL', 'number of characters per row', Integer) do |v|
            params.width = v
          end
          opt.on('-h', '--height VAL', 'number of rows', Numeric) do |v|
            params.height = v
          end
          opt.on('-b', '--border VAL', 'specify the style of the bounding box', String) do |v|
            params.border = v.to_sym
          end
          opt.on('-m', '--margin VAL', 'number of spaces to the left of the plot', Numeric) do |v|
            params.margin = v
          end
          opt.on('-p', '--padding VAL', 'space of the left and right of the plot', Numeric) do |v|
            params.padding = v
          end
          opt.on('-c', '--color VAL', 'color of the drawing', String) do |v|
            params.color = v =~ /\A[0-9]+\z/ ? v.to_i : v.to_sym
          end
          opt.on('--[no-]labels', 'hide the labels', TrueClass) do |v|
            params.labels = v
          end
          opt.on('--fmt VAL', 'xyy, xyxy', String) do |v|
            @fmt = v
          end
          opt.on('--debug', TrueClass) do |v|
            @debug = v
          end
          yield opt if block_given?
        end
      end

      def main_parser
        @main_parser ||= create_default_parser do |main_parser|
          # Usage and help messages
          main_parser.banner = \
            <<~MSG
              Program: uplot (Tools for plotting on the terminal)
              Version: #{Uplot::VERSION} (using unicode_plot #{UnicodePlot::VERSION})

              Usage:   uplot <command> [options]

              Command: barplot    bar
                       histogram  hist
                       lineplot   line
                       scatter    s
                       density    d
                       boxplot    box
                       colors

              Options:
            MSG
        end
      end

      def sub_parser
        @sub_parser ||= create_default_parser do |parser|
          parser.banner = <<~MSG
            Usage: uplot #{command} [options]

            Options:
          MSG

          case command
          when nil
            warn main_parser.help
            exit 1

          when :barplot, :bar
            parser.on('--symbol VAL', String) do |v|
              params.symbol = v
            end
            parser.on('--xscale VAL', String) do |v|
              params.xscale = v
            end

          when :count, :c
            parser.on('--symbol VAL', String) do |v|
              params.symbol = v
            end

          when :histogram, :hist
            parser.on('-n', '--nbins VAL', Numeric) do |v|
              params.nbins = v
            end
            parser.on('--closed VAL', String) do |v|
              params.closed = v
            end
            parser.on('--symbol VAL', String) do |v|
              params.symbol = v
            end

          when :lineplot, :line
            parser.on('--canvas VAL', String) do |v|
              params.canvas = v
            end
            parser.on('--xlim VAL', Array) do |v|
              params.xlim = v.take(2)
            end
            parser.on('--ylim VAL', Array) do |v|
              params.ylim = v.take(2)
            end

          when :lineplots, :lines
            parser.on('--canvas VAL', String) do |v|
              params.canvas = v
            end
            parser.on('--xlim VAL', Array) do |v|
              params.xlim = v.take(2)
            end
            parser.on('--ylim VAL', Array) do |v|
              params.ylim = v.take(2)
            end

          when :scatter, :s
            parser.on('--canvas VAL', String) do |v|
              params.canvas = v
            end
            parser.on('--xlim VAL', Array) do |v|
              params.xlim = v.take(2)
            end
            parser.on('--ylim VAL', Array) do |v|
              params.ylim = v.take(2)
            end

          when :density, :d
            parser.on('--grid', TrueClass) do |v|
              params.grid = v
            end
            parser.on('--xlim VAL', Array) do |v|
              params.xlim = v.take(2)
            end
            parser.on('--ylim VAL', Array) do |v|
              params.ylim = v.take(2)
            end

          when :boxplot, :box
            parser.on('--xlim VAL', Array) do |v|
              params.xlim = v.take(2)
            end

          when :colors
            parser.on('-n', '--names', TrueClass) do |v|
              @color_names = v
            end

          else
            warn "uplot: unrecognized command '#{command}'"
            exit 1
          end
        end
      end

      def parse_options(argv = ARGV)
        begin
          main_parser.order!(argv)
        rescue OptionParser::ParseError => e
          warn "uplot: #{e.message}"
          exit 1
        end

        @command = argv.shift&.to_sym

        begin
          sub_parser.parse!(argv)
        rescue OptionParser::ParseError => e
          warn "uplot: #{e.message}"
          exit 1
        end
      end
    end
  end
end
