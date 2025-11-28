# rbs_inline: enabled
# frozen_string_literal: true

module RailroadDiagrams
  # minimum vertical separation between things. For a 3px stroke, must be at least 4
  VS = 8 #: Integer

  # radius of arcs
  AR = 10 #: Integer

  # class to put on the root <svg>
  DIAGRAM_CLASS = 'railroad-diagram' #: String

  # is the stroke width an odd (1px, 3px, etc) pixel length?
  STROKE_ODD_PIXEL_LENGTH = true #: bool

  # how to align items when they have extra space. left/right/center
  INTERNAL_ALIGNMENT = 'center' #: String

  # width of each monospace character. play until you find the right value for your font
  CHAR_WIDTH = 8.5 #: Float

  # comments are in smaller text by default
  COMMENT_CHAR_WIDTH = 7 #: Integer

  # @rbs val: String | Numeric
  # @rbs return: String
  def self.escape_attr(val)
    return val.gsub('&', '&amp;').gsub("'", '&apos;').gsub('"', '&quot;') if val.is_a?(String)

    '%g' % val
  end

  # @rbs val: String
  # @rbs return: String
  def self.escape_html(val)
    escape_attr(val).gsub('<', '&lt;')
  end
end

require_relative 'railroad_diagrams/diagram_item'
require_relative 'railroad_diagrams/diagram_multi_container'

require_relative 'railroad_diagrams/alternating_sequence'
require_relative 'railroad_diagrams/choice'
require_relative 'railroad_diagrams/command'
require_relative 'railroad_diagrams/comment'
require_relative 'railroad_diagrams/diagram'
require_relative 'railroad_diagrams/end'
require_relative 'railroad_diagrams/group'
require_relative 'railroad_diagrams/horizontal_choice'
require_relative 'railroad_diagrams/multiple_choice'
require_relative 'railroad_diagrams/non_terminal'
require_relative 'railroad_diagrams/one_or_more'
require_relative 'railroad_diagrams/optional_sequence'
require_relative 'railroad_diagrams/optional'
require_relative 'railroad_diagrams/path'
require_relative 'railroad_diagrams/sequence'
require_relative 'railroad_diagrams/skip'
require_relative 'railroad_diagrams/stack'
require_relative 'railroad_diagrams/start'
require_relative 'railroad_diagrams/style'
require_relative 'railroad_diagrams/terminal'
require_relative 'railroad_diagrams/text_diagram'
require_relative 'railroad_diagrams/version'
require_relative 'railroad_diagrams/zero_or_more'
