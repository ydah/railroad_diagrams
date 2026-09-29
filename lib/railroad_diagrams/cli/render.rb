# frozen_string_literal: true

require 'fileutils'
require 'json'
require 'optparse'
require_relative '../importers/w3c_ebnf'
require_relative '../importers/yaml_grammar'
require_relative '../transform/simplifier'

module RailroadDiagrams
  module CLI
    class Render
      FORMATS = %w[svg standalone html text ascii unicode json].freeze
      INPUT_FORMATS = %w[rb yaml json ebnf].freeze
      EXTENSIONS = { '.rb' => 'rb', '.yml' => 'yaml', '.yaml' => 'yaml',
                     '.json' => 'json', '.ebnf' => 'ebnf' }.freeze
      OUTPUT_EXTENSIONS = { 'svg' => 'svg', 'standalone' => 'svg', 'html' => 'html',
                            'text' => 'txt', 'ascii' => 'txt', 'unicode' => 'txt', 'json' => 'json' }.freeze

      def initialize
        @format = 'html'
        @output = '-'
        @rules = []
        @theme = :default
      end

      def run(argv)
        parser = OptionParser.new do |opts|
          opts.banner = 'Usage: railroad_diagrams render INPUT... [options]'
          opts.on('-f', '--format FORMAT', FORMATS, "Output format (#{FORMATS.join(', ')})") { |value| @format = value }
          opts.on('-i', '--input-format FORMAT', INPUT_FORMATS, 'Input format for all inputs') { |value| @input_format = value }
          opts.on('-o', '--output PATH', 'Output file, directory, or -') { |value| @output = value }
          opts.on('--split', 'Write one file per rule') { @split = true }
          opts.on('--rule NAME', 'Render only this rule (repeatable)') { |name| @rules << name }
          opts.on('--theme NAME', 'Built-in theme') { |name| @theme = name.to_sym }
          opts.on('--css FILE', 'Append custom CSS from a file') { |path| @css_path = path }
          opts.on('--max-width WIDTH', Float, 'Wrap SVG diagrams to this width') { |width| @max_width = width }
          opts.on('--charset NAME', %w[ascii unicode], 'Text output character set') { |name| @charset = name.to_sym }
          opts.on('--simplify', 'Simplify grammar nodes') { @simplify = true }
          opts.on('--lint', 'Print grammar warnings') { @lint = true }
          opts.on('--watch', 'Regenerate when input files change') { @watch = true }
          opts.on('-h', '--help', 'Print this help') do
            puts opts
            puts '.rb input executes arbitrary Ruby code. Only render trusted files.'
            return 0
          end
        end
        parser.parse!(argv)
        @inputs = argv
        validate_options!
        @css = File.read(@css_path) if @css_path
        @watch ? watch : render_once
      end

      private

      def validate_options!
        raise UsageError, 'at least one input is required' if @inputs.empty?
        raise UsageError, '--input-format is required for standard input' if @inputs.include?('-') && !@input_format
        raise UsageError, 'Ruby input must be an explicit file path' if @inputs.include?('-') && @input_format == 'rb'
        raise UsageError, '--split requires an output directory' if @split && @output == '-'
        raise UsageError, '--watch requires file inputs' if @watch && @inputs.include?('-')
        raise UsageError, '--max-width must be positive and finite' if @max_width && (!@max_width.finite? || @max_width <= 0)
        raise UsageError, '--css is supported only for HTML and standalone SVG' if @css_path && !%w[html standalone].include?(@format)

        Theme[@theme]
        validate_input_formats!
      rescue InvalidArgument => e
        raise UsageError, e.message
      end

      def validate_input_formats!
        @inputs.each do |input|
          next if input == '-' || @input_format || EXTENSIONS.key?(File.extname(input).downcase)

          raise UsageError, "cannot infer input format: #{input}"
        end
      end

      def render_once
        document = load_document
        document.lint.each { |warning| warn warning.message } if @lint
        if @split
          write_split(document)
        else
          write_output(render_document(document))
        end
        0
      end

      def load_document
        documents = @inputs.map { |path| load_input(path) }
        title = documents.size == 1 ? documents.first.title : 'Grammar'
        document = Document.new(title: title, theme: @theme)
        documents.each do |source|
          source.rules.each do |name, node|
            next if !@rules.empty? && !@rules.include?(name)

            node = Transform::Simplifier.call(node, rule_name: name) if @simplify
            document.add_rule(name, node)
          end
        end
        missing = @rules - document.rules.map(&:first)
        raise ParseError, "unknown rule(s): #{missing.join(', ')}" unless missing.empty?

        document
      end

      def load_input(path)
        format = @input_format || EXTENSIONS.fetch(File.extname(path).downcase)
        source = path == '-' ? $stdin.read : File.read(path)
        case format
        when 'ebnf' then Importers::W3cEbnf.parse(source, filename: path)
        when 'yaml' then Importers::YamlGrammar.parse(source, filename: path)
        when 'json' then parse_json(source, path)
        else parse_ruby(source, path)
        end
      rescue JSON::ParserError => e
        raise ParseError, "#{path}: #{e.message}"
      end

      def parse_json(source, path)
        value = JSON.parse(source)
        return single_rule(path, RailroadDiagrams.from_h(value)) unless value.is_a?(Hash) && value['rules'].is_a?(Hash)

        unknown = value.keys - %w[title rules]
        raise ParseError, "#{path}: unknown field(s): #{unknown.join(', ')}" unless unknown.empty?

        title = value.fetch('title', 'Grammar')
        raise ParseError, "#{path}: title must be a string" unless title.is_a?(String)

        document = Document.new(title: title)
        value['rules'].each { |name, item| document.add_rule(name, RailroadDiagrams.from_h(item)) }
        document
      end

      def parse_ruby(source, path)
        result = Builder.new.instance_eval(source, path, 1)
        return result if result.is_a?(Document)
        return single_rule(path, result) if result.is_a?(DiagramItem)

        raise ParseError, "#{path}: Ruby input must return a diagram node or Document"
      rescue StandardError, SyntaxError => e
        raise ParseError, "#{path}: #{e.message}"
      end

      def single_rule(path, node)
        Document.new.add_rule(File.basename(path, File.extname(path)).sub(/\A-\z/, 'stdin'), node)
      end

      def render_document(document)
        return document.to_html(max_width: @max_width, css: @css) if @format == 'html'
        return "#{JSON.generate(document_json(document))}\n" if @format == 'json'

        document.rules.map { |name, node| render_rule(name, node) }.join("\n")
      rescue StandardError => e
        raise RenderError, e.message
      end

      def document_json(document)
        return document.rules.first[1].to_h if document.rules.size == 1

        { 'title' => document.title, 'rules' => document.rules.map { |name, node| [name, node.to_h] }.to_h }
      end

      def render_rule(name, node)
        return "#{JSON.generate(node.to_h)}\n" if @format == 'json'

        diagram = node.is_a?(Diagram) ? node : Diagram.new(node)
        options = { theme: @theme, max_width: @max_width }
        case @format
        when 'svg' then diagram.to_svg(**options)
        when 'standalone'
          css = @css && "#{Theme[@theme].css(css_variables: false)}\n#{@css}"
          diagram.to_standalone_svg(css: css, **options)
        when 'html' then Document.new(title: name, theme: @theme).add_rule(name, node)
                                 .to_html(max_width: @max_width, css: @css)
        when 'ascii', 'text', 'unicode'
          charset = @charset || (@format == 'ascii' ? :ascii : :unicode)
          "#{name}:\n#{diagram.to_text(charset: charset)}"
        end
      rescue StandardError => e
        raise RenderError, e.message
      end

      def write_split(document)
        raise UsageError, '--split requires a directory' if File.file?(@output)

        FileUtils.mkdir_p(@output)
        seen = Hash.new(0)
        document.rules.each do |name, node|
          slug = name.downcase.gsub(/[^a-z0-9]+/, '-').gsub(/\A-|-\z/, '')
          slug = 'rule' if slug.empty?
          seen[slug] += 1
          slug = "#{slug}-#{seen[slug]}" if seen[slug] > 1
          path = File.join(@output, "#{slug}.#{OUTPUT_EXTENSIONS.fetch(@format)}")
          File.write(path, render_rule(name, node))
        end
      rescue SystemCallError => e
        raise RenderError, e.message
      end

      def write_output(text)
        return print text if @output == '-'

        path = if File.directory?(@output) || @output.end_with?(File::SEPARATOR)
                 FileUtils.mkdir_p(@output)
                 File.join(@output, "index.#{OUTPUT_EXTENSIONS.fetch(@format)}")
               else
                 @output
               end
        File.write(path, text)
      rescue SystemCallError => e
        raise RenderError, e.message
      end

      def watch
        previous = @inputs.map { |path| File.mtime(path) }
        render_once
        loop do
          sleep 0.5
          current = input_mtimes
          next if current == previous

          previous = current
          render_once
        rescue ParseError, RenderError => e
          warn "railroad_diagrams: #{e.message}"
        end
      rescue Interrupt
        0
      end

      def input_mtimes
        @inputs.map do |path|
          File.mtime(path)
        rescue SystemCallError
          nil
        end
      end
    end
  end
end
