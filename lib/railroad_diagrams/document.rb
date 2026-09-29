# frozen_string_literal: true

require 'erb'

module RailroadDiagrams
  class Document
    attr_reader :title, :theme, :locale, :rules

    def initialize(title: 'Grammar', theme: :auto, locale: :en)
      raise InvalidArgument, 'title must be a String' unless title.is_a?(String)

      Theme[theme]
      I18n.t(:describe_truncated, locale: locale)
      @title = title
      @theme = theme
      @locale = locale
      @rules = []
    end

    def add_rule(name, node)
      raise InvalidArgument, 'rule name must be a nonempty String' unless name.is_a?(String) && !name.empty?
      raise InvalidArgument, 'rule body must be a DiagramItem' unless node.is_a?(DiagramItem)

      @rules << [name, node]
      self
    end

    def lint
      Transform::Lint.call(@rules)
    end

    def rule_sections(max_width: nil)
      ids = rule_ids
      targets = @rules.each_with_index.with_object({}) { |((name, _), index), found| found[name] ||= ids[index] }
      references = @rules.map do |_, node|
        node.each_node.grep(NonTerminal).map { |item| item.instance_variable_get(:@text) }.uniq
      end

      @rules.each_with_index.map do |(name, node), index|
        diagram = Marshal.load(Marshal.dump(node))
        diagram.each_node do |item|
          next unless item.is_a?(NonTerminal) && item.instance_variable_get(:@href).nil?

          target = targets[item.instance_variable_get(:@text)]
          item.instance_variable_set(:@href, "##{target}") if target
        end
        diagram = Diagram.new(diagram) unless diagram.is_a?(Diagram)
        {
          name: name, id: ids[index],
          svg: diagram.to_svg(theme: @theme, locale: @locale, href_mode: :href, id_prefix: "r#{index}-", max_width: max_width),
          text: diagram.to_text(charset: :unicode),
          referenced_by: @rules.each_index.select { |source| references[source].include?(name) }.map { |source| @rules[source].first }.uniq
        }
      end
    end

    def to_html(interactive: true, index: :definition, max_width: nil, css: nil)
      raise InvalidArgument, 'index must be :definition or :alphabetical' unless %i[definition alphabetical].include?(index)
      raise InvalidArgument, 'CSS must be a String without </style>' if css && (!css.is_a?(String) || css.match?(%r{</style}i))

      sections = rule_sections(max_width: max_width)
      navigation = index == :alphabetical ? sections.sort_by { |section| section[:name].downcase } : sections
      warnings = lint
      stylesheet = [Theme[@theme].css(css_variables: false), css].compact.join("\n")
      labels = if @locale == :ja
                 { rules: '規則', search: '規則を検索', text: 'テキスト図', referenced_by: '参照元', warnings: '文法の警告' }
               else
                 { rules: 'Rules', search: 'Search rules', text: 'Text diagram', referenced_by: 'Referenced by', warnings: 'Lint warnings' }
               end
      ERB.new(File.read(File.expand_path('templates/document.erb', __dir__))).result(binding)
    end

    private

    def rule_ids
      seen = Hash.new(0)
      @rules.map do |name, _|
        slug = name.downcase.gsub(/[^a-z0-9]+/, '-').gsub(/\A-|-\z/, '')
        slug = 'rule' if slug.empty?
        seen[slug] += 1
        seen[slug] == 1 ? "rule-#{slug}" : "rule-#{slug}-#{seen[slug]}"
      end
    end
  end
end
