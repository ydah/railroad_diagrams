# asciidoctor-railroad

Asciidoctor の `[railroad]` ブロックから構文図を生成する拡張の雛形です。ブロックの中身は `railroad_diagrams` の YAML 文法形式で書きます。

## 導入

本リポジトリから gem をビルドしてインストールした後、Asciidoctor の `-r` オプションで読み込みます。

```sh
gem install asciidoctor-railroad
asciidoctor -r asciidoctor-railroad sample/index.adoc
```

`sample/index.adoc` は単独で HTML に変換できるサンプルです。開発中は本リポジトリの `lib/` とこの gem の `lib/` を Ruby のロードパスに追加してください。

```asciidoc
[railroad]
----
rules:
  statement:
    - SELECT
    - <table>
  table: name
----
```

各規則は見出し付きの SVG 図になります。
