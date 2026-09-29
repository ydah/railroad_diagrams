# RailroadDiagrams 1.0

RailroadDiagrams 1.0 is the first release with a documented stability promise for its Ruby API. Existing diagrams still render with the same default SVG precision and link attributes. See [API stability](api_stability.md) for the supported names and [the migration guide](migration.md) for changes since 0.3.

You can now build a diagram with constructors or a short Ruby DSL, import W3C EBNF and safe YAML grammar files, and render a linked HTML document for all rules:

```bash
railroad_diagrams render grammar.ebnf -o grammar.html --format html --simplify --lint
```

SVG and text output are also available from the CLI or Ruby API. The [gallery](https://ydah.github.io/railroad_diagrams/) shows every node in each bundled theme. The [playground](https://ydah.github.io/railroad_diagrams/playground.html) runs the library in the browser and keeps working after its assets are cached offline.

Rails views can use `railroad_diagram { ... }` after requiring `railroad_diagrams/rails`. Jekyll and Asciidoctor adapters are provided as separate gem projects in `integrations/`, with sample sites. The main gem keeps Ruby 2.5 support and does not load those frameworks unless asked.

The release is published by the [tag workflow](../.github/workflows/release.yml) through RubyGems Trusted Publishing. Install it with `gem install railroad_diagrams`.
