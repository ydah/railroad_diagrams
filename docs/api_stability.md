# API stability in 1.x

This page classifies the constants returned by `RailroadDiagrams.constants(false)` and the methods returned by `public_instance_methods(false)` on their classes and modules. A Ruby `public` method is not automatically a supported extension point. The category below also applies to a constant's methods unless a method is listed separately.

## Stable

Stable APIs retain source compatibility throughout 1.x. Removal requires 2.0.

| API | Covered methods |
| --- | --- |
| `Diagram`, `ComplexDiagram` | Constructors; `Diagram#to_svg`, `#to_standalone_svg`, `#to_text`, `#to_html`, `#to_markdown`, `#write_svg`, `#write_standalone`, `#write_text` |
| `Terminal`, `NonTerminal`, `Comment`, `CharClass`, `Special`, `Skip`, `Start`, `End`, `Block` | Constructors and documented node attributes |
| `Sequence`, `Stack`, `Choice`, `MultipleChoice`, `HorizontalChoice`, `OptionalSequence`, `AlternatingSequence`, `Optional`, `OneOrMore`, `ZeroOrMore`, `Repeat`, `SeparatedList`, `Except`, `Group` | Constructors and documented node attributes |
| `DiagramItem` | `#child_nodes`, `#each_node`, `#each`, `#==`, `#eql?`, `#hash`, `#inspect`, `#to_h`, `#to_json`, `#to_yaml` |
| `RailroadDiagrams` | `.configure`, `.default_options`, `.diagram`, `.build`, `.from_h`, `.from_json`, `.from_yaml` |
| `Builder`, `DSL` | DSL methods `diagram`, `t`/`terminal`, `nt`/`non_terminal`, `comment`, `seq`, `stack`, `choice`, `hchoice`, `mchoice`, `opt`, `zero_or_more`, `one_or_more`, `oseq`, `alt`, `group`, `skip`, `repeat`, `list`, `except`, `block`, `char_class`, `special` |
| `Options` | Configuration fields and `#merge` |
| `Style` | `.default_style` |
| `Theme` | `.[]` and named built-in themes; theme **token keys** are experimental |
| `Document` | Constructor, `#add_rule`, `#rules`, `#title`, `#theme`, `#locale`, `#to_html`, `#rule_sections`, `#lint` |
| `Importers::W3cEbnf`, `Importers::YamlGrammar` | `.parse` |
| `InvalidArgument`, `ParseError`, `RenderError`, `Error` | Exception classes, `ParseError#line`, `#column`, `#source_line` |
| `VERSION`, `Command` | Version constant and legacy command entry point |

`DiagramItem#to_h`, `#to_json`, and `#to_yaml` are supplied by `Serialization::Node`. The stable contract is the serialized result, not that module's helper methods. `Document#rules` keeps definition order as `[name, node]` pairs.

## Experimental

These APIs may change in a minor release, with changes recorded in the changelog.

| API | Covered methods |
| --- | --- |
| `Transform::Simplifier`, `Transform::AutoWrap`, `Transform::Lint` | Public transform methods, flags, and warning records |
| `Theme#tokens` | Token names and token values; `Theme#css` and `#inline_style` are renderer support methods |
| `Rails` | Optional Rails integration and its methods; Jekyll and Asciidoctor adapters are separate gems |
| CLI command line | Subcommands and options added during the 0.x series; parser classes under `CLI` are internal |

## Internal

These constants and methods are exposed by Ruby but are implementation details and can change without notice. `Path` and `TextDiagram` retain their class names for compatibility; their construction and composition methods are internal.

| API | Covered methods |
| --- | --- |
| `Path`, `TextDiagram`, `Svg`, `Text` | Geometry, SVG element/serializer, and text composition methods |
| `Context`, `Metrics`, `Measurer`, `IdGenerator`, `Writer`, `Unicode` | Rendering state, measurement, IDs, writing, and Unicode tables |
| `DiagramMultiContainer`, `ExpandedNode`, `ResetChildrenOnFormat`, `Serialization`, `Introspection`, `Coercion` | Base class and helper implementations |
| `A11y`, `I18n`, `LinkPolicy`, `Deprecation` | Rendering support and validation helpers |
| `CLI` | Command dispatch implementation classes and methods |
| `RailroadDiagrams.escape_attr`, `.escape_html`, `.format_number` | Serialization helpers |
| `DEFAULT_OPTIONS`, `AR`, `VS`, `CHAR_WIDTH`, `COMMENT_CHAR_WIDTH`, `DIAGRAM_CLASS`, `STROKE_ODD_PIXEL_LENGTH`, `INTERNAL_ALIGNMENT` | Defaults and legacy rendering constants |
| All node classes | `#format`, `#measure`, `#render_svg`, `#render_text`, `#text_diagram`, `#walk`, `#add`, `#to_s`, raw metric readers (`#up`, `#down`, `#height`, `#width`, `#needs_space`) and mutable `#attrs`/`#children` |
| `DiagramItem`, `Style`, `Theme` | Any public methods not listed in Stable or Experimental above |

The last row classifies methods such as `DiagramItem#write_svg` when called on a bare node, `Style#add`, and `Theme#inline_style`. The stable `write_svg` promise applies to `Diagram`.

## Defaults fixed for 1.x

- `Options#precision` stays `nil`. Rendering keeps the existing full precision by default; callers can set an explicit precision when required.
- `Options#href_mode` stays `:xlink`. Changing to `:href` or `:both` would change existing SVG bytes and consumer behavior. Callers can opt in explicitly.

## Repeating the audit

Run the following after API changes and update the rows above for every new constant or method:

```ruby
require 'railroad_diagrams'
puts RailroadDiagrams.constants(false).sort
RailroadDiagrams.constants(false).sort.each do |name|
  value = RailroadDiagrams.const_get(name)
  next unless value.is_a?(Module)

  puts "#{name}: #{value.public_instance_methods(false).sort.join(', ')}"
end
```
