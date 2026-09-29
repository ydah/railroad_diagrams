# frozen_string_literal: true

require 'json'
require 'railroad_diagrams'
require_relative '../../spec/support/examples_loader'

module ParityExport
  module_function

  def node(item)
    name = item.class.name.split('::').last
    args = case name
           when 'Terminal', 'NonTerminal', 'Comment'
             %i[@text @href @title @cls].map { |field| item.instance_variable_get(field) }
           when 'Choice'
             [item.instance_variable_get(:@default)] + item.instance_variable_get(:@items).map { |child| node(child) }
           when 'MultipleChoice'
             [item.instance_variable_get(:@default), item.instance_variable_get(:@type)] +
             item.instance_variable_get(:@items).map { |child| node(child) }
           when 'Group'
             label = item.instance_variable_get(:@label)
             [node(item.instance_variable_get(:@item)), label && node(label)]
           when 'OneOrMore'
             [node(item.instance_variable_get(:@item)), node(item.instance_variable_get(:@rep))]
           when 'Start'
             [item.instance_variable_get(:@type), item.instance_variable_get(:@label)]
           when 'End'
             [item.instance_variable_get(:@type)]
           when 'Skip'
             []
           else
             item.instance_variable_get(:@items).map { |child| node(child) }
           end
    { 'class' => name, 'args' => args }
  end

  def examples
    ExamplesLoader.load.transform_values { |diagram| node(diagram) }
  end
end

puts JSON.generate(ParityExport.examples) if $PROGRAM_NAME == __FILE__
