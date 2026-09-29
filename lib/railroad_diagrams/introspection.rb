# frozen_string_literal: true

module RailroadDiagrams
  module Introspection
    NAMES = {
      'terminal' => 't', 'non_terminal' => 'nt', 'comment' => 'comment',
      'sequence' => 'seq', 'stack' => 'stack', 'choice' => 'choice',
      'optional' => 'opt', 'zero_or_more' => 'zero_or_more', 'one_or_more' => 'one_or_more',
      'horizontal_choice' => 'hchoice', 'multiple_choice' => 'mchoice',
      'optional_sequence' => 'oseq', 'alternating_sequence' => 'alt',
      'group' => 'group', 'skip' => 'skip', 'diagram' => 'diagram',
      'repeat' => 'repeat', 'separated_list' => 'list', 'except' => 'except',
      'block' => 'block', 'char_class' => 'char_class', 'special' => 'special'
    }.freeze

    module_function

    def call(node)
      format(node.to_h)
    rescue ParseError
      "DiagramItem(#{node.instance_variable_get(:@name)}, #{node.attrs}, #{node.children})"
    end

    # rubocop:disable-next Metrics/CyclomaticComplexity
    def format(value)
      type = value.fetch('type')
      return "#{type.capitalize}.new(#{value.fetch('diagram_type').inspect}#{keyword(value, 'label')})" if %w[start end].include?(type)

      name = NAMES.fetch(type)
      arguments = case type
                  when 'terminal', 'non_terminal', 'comment', 'char_class', 'special'
                    [value.fetch('text').inspect, *keywords(value, %w[href title])]
                  when 'sequence', 'stack', 'horizontal_choice', 'optional_sequence', 'alternating_sequence'
                    value.fetch('items').map { |item| format(item) }
                  when 'diagram'
                    options = keywords(value, %w[title desc])
                    options << 'desc: :auto' if value['desc_auto']
                    options << 'type: "complex"' if value['diagram_type'] == 'complex'
                    [*value.fetch('items').map { |item| format(item) }, *options]
                  when 'choice', 'multiple_choice'
                    [*([value.fetch('choice_type').inspect] if type == 'multiple_choice'),
                     *value.fetch('items').map { |item| format(item) }, "default: #{value.fetch('default')}"]
                  when 'optional'
                    [format(value.fetch('item')), *(['skip: true'] if value['skip'])]
                  when 'zero_or_more'
                    [format(value.fetch('item')), format(value.fetch('repeat')), *(['skip: true'] if value['skip'])]
                  when 'one_or_more'
                    [format(value.fetch('item')), format(value.fetch('repeat'))]
                  when 'group'
                    [format(value.fetch('item')), *(["label: #{format(value['label'])}"] if value['label'])]
                  when 'repeat'
                    [format(value.fetch('item')), *keywords(value, %w[min max separator label])]
                  when 'separated_list'
                    [format(value.fetch('item')), "sep: #{format(value.fetch('separator'))}",
                     *keywords(value, %w[min trailing])]
                  when 'except'
                    excluded = value.fetch('excluded')
                    [format(value.fetch('item')), excluded.is_a?(Hash) ? format(excluded) : excluded.inspect,
                     *keywords(value, %w[label])]
                  when 'block'
                    keywords(value, %w[width up height down needs_space])
                  else
                    []
                  end
      arguments.concat(keywords(value, %w[id cls attrs]))
      "#{name}(#{arguments.join(', ')})"
    end

    def keywords(value, names)
      names.map { |name| "#{name == 'diagram_type' ? 'type' : name}: #{render_value(value[name])}" if value.key?(name) }.compact
    end

    def keyword(value, name)
      value.key?(name) ? ", #{name}: #{render_value(value[name])}" : ''
    end

    def render_value(value)
      return ':auto' if value == { 'auto' => true }
      return format(value) if value.is_a?(Hash) && value.key?('type')

      value.inspect
    end
  end
end
