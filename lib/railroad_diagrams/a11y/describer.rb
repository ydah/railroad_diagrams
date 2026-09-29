# rbs_inline: enabled
# frozen_string_literal: true

require_relative '../i18n'

module RailroadDiagrams
  module A11y
    module Describer
      DEFAULT_MAX_LENGTH = 200

      module_function

      # @rbs node: DiagramItem
      # @rbs locale: Symbol
      # @rbs max_length: Integer
      # @rbs return: String
      def call(node, locale: :en, max_length: DEFAULT_MAX_LENGTH)
        raise InvalidArgument, 'max_length must be a positive integer' unless max_length.is_a?(Integer) && max_length.positive?

        ellipsis = I18n.t(:describe_truncated, locale: locale)
        description = describe(node, locale)
        graphemes = description.each_grapheme_cluster.take(max_length + 1)
        return description if graphemes.length <= max_length

        graphemes.first(max_length - 1).join + ellipsis
      end

      def describe(node, locale)
        case node
        when Terminal, NonTerminal, Comment
          describe_label(node, locale)
        when Start then I18n.t(:describe_start, locale: locale)
        when End then I18n.t(:describe_end, locale: locale)
        when Skip then I18n.t(:describe_skip, locale: locale)
        when Style then ''
        when Diagram
          describe_list(:describe_sequence, node.child_nodes.reject { |child| child.is_a?(Start) || child.is_a?(End) }, locale)
        when Sequence, Stack
          describe_list(:describe_sequence, node.child_nodes, locale)
        when OptionalSequence
          items = node.child_nodes.map do |child|
            I18n.t(:describe_optional, locale: locale, item: describe(child, locale))
          end
          describe_joined(:describe_sequence, items, locale)
        when HorizontalChoice, AlternatingSequence
          describe_list(:describe_choice, node.child_nodes, locale)
        when MultipleChoice
          key = node.instance_variable_get(:@type) == 'all' ? :describe_multiple_choice_all : :describe_multiple_choice_any
          describe_list(key, node.child_nodes, locale)
        when Choice
          describe_choice(node, locale)
        when OneOrMore
          I18n.t(:describe_one_or_more, locale: locale, item: describe(node.child_nodes.first, locale))
        when Group
          item, label = node.child_nodes
          return describe(item, locale) unless label

          I18n.t(:describe_group, locale: locale, label: describe(label, locale), item: describe(item, locale))
        else
          raise InvalidArgument, "unsupported diagram node: #{node.class}"
        end
      end

      def describe_label(node, locale)
        key = case node
              when Terminal then :describe_terminal
              when NonTerminal then :describe_non_terminal
              else :describe_comment
              end
        I18n.t(key, locale: locale, text: node.instance_variable_get(:@text))
      end

      def describe_choice(node, locale)
        children = node.child_nodes
        if children.length == 2 && children.one?(Skip)
          item = children.find { |child| !child.is_a?(Skip) }
          return describe_zero_or_more(item, locale) if item.is_a?(OneOrMore)

          return I18n.t(:describe_optional, locale: locale, item: describe(item, locale))
        end

        describe_list(:describe_choice, children, locale)
      end

      def describe_zero_or_more(item, locale)
        I18n.t(:describe_zero_or_more, locale: locale, item: describe(item.child_nodes.first, locale))
      end

      def describe_list(key, children, locale)
        describe_joined(key, children.map { |child| describe(child, locale) }, locale)
      end

      def describe_joined(key, descriptions, locale)
        descriptions = descriptions.reject(&:empty?)
        return '' if descriptions.empty?

        separator = I18n.t(:describe_separator, locale: locale)
        I18n.t(key, locale: locale, items: descriptions.join(separator))
      end
    end
  end
end
