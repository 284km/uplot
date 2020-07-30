require 'optparse'
require 'csv'

module Uplot
  class Command
    def initialize(argv)
      @params = {}
      @ptype = nil
      @headers = nil
      @delimiter = "\t"
      @output = false
      parse_options(argv)
    end

    def opt_new
      opt = OptionParser.new do |opt|
        opt.on('-o', '--output', TrueClass) { |v| @output = v }
        opt.on('-d', '--delimiter VAL', String) { |v| @delimiter = v }
        opt.on('-H', '--headers', TrueClass) { |v| @headers = v }
        opt.on('-t', '--title VAL', String) { |v| @params[:title] = v }
        opt.on('-w', '--width VAL', Numeric) { |v| @params[:width] = v }
        opt.on('-h', '--height VAL', Numeric) { |v| @params[:height] = v }
        opt.on('-b', '--border VAL', Numeric) { |v| @params[:border] = v }
        opt.on('-m', '--margin VAL', Numeric) { |v| @params[:margin] = v }
        opt.on('-p', '--padding VAL', Numeric) { |v| @params[:padding] = v }
        opt.on('-l', '--labels', TrueClass) { |v| @params[:labels] = v }
      end
    end

    def parse_options(argv)
      main_parser            = opt_new
      parsers                = {}
      parsers['hist']        = opt_new.on('--nbins VAL', Numeric) { |v| @params[:nbins] = v }
      parsers['histogram']   = parsers['hist']
      parsers['line']        = opt_new
      parsers['lineplot']    = parsers['line']
      parsers['lines']       = opt_new
      parsers['scatter']     = opt_new
      parsers['scatterplot'] = parsers['scatter']
      parsers['bar']         = opt_new
      parsers['barplot']         = parsers['bar']

      main_parser.banner = <<~MSG
        Usage:\tuplot <command> [options]
        Command:\t#{parsers.keys.join(' ')}
      MSG
      main_parser.order!(argv)
      @ptype = argv.shift

      unless parsers.has_key?(@ptype)
        warn "unrecognized command '#{@ptype}'"
        exit 1
      end
      parser = parsers[@ptype]
      parser.parse!(argv) unless argv.empty?
    end

    def run
      # Sometimes the input file does not end with a newline code.
      while input = Kernel.gets(nil)
        input.freeze
        data, headers = preprocess(input)
        case @ptype
        when 'hist', 'histogram'
          histogram(data, headers)
        when 'line', 'lineplot'
          line(data, headers)
        when 'lines'
          lines(data, headers)
        when 'scatter', 'scatterplot'
          scatter(data, headers)
        when 'bar', 'barplot'
          barplot(data, headers)
        end.render($stderr)

        print input if @output
      end
    end

    def preprocess(input)
      data = CSV.parse(input, col_sep: @delimiter)
      if @headers
        headers = data.shift
        data = data.transpose
        [data, headers]
      else
        data = data.transpose
        [data, nil]
      end
    end

    def barplot(data, headers)
      @params[:title] ||= headers[1] if headers
      UnicodePlot.barplot(data[0], data[1].map(&:to_f), **@params)
    end

    def histogram(data, headers)
      @params[:title] ||= headers[0] if headers # labels?
      series = data[0].map(&:to_f)
      UnicodePlot.histogram(series, **@params.compact)
    end

    def line(data, headers)
      if data.size == 1
        @params[:name] ||= headers[0] if headers
        y = data[0]
        x = (1..y.size).to_a
      else
        @params[:name] ||= headers[1] if headers
        x = data[0]
        y = data[1]
      end
      x = x.map(&:to_f)
      y = y.map(&:to_f)
      UnicodePlot.lineplot(x, y, **@params.compact)
    end

    def lines(data, headers)
      data.map! { |series| series.map(&:to_f) }
      @params[:name] ||= headers[1] if headers
      plot = UnicodePlot.lineplot(data[0], data[1], **@params.compact)
      2.upto(data.size - 1) do |i|
        UnicodePlot.lineplot!(plot, data[0], data[i], name: headers[i])
      end
      plot
    end

    def scatter(data, headers)
      data.map! { |series| series.map(&:to_f) }
      @params[:name] ||= headers[1] if headers
      plot = UnicodePlot.scatterplot(data[0], data[1], **@params.compact)
      2.upto(data.size - 1) do |i|
        UnicodePlot.scatterplot!(plot, data[0], data[i], name: headers[i])
      end
      plot
    end
  end
end
