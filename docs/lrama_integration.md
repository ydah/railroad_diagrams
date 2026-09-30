# Lrama の構文図に規則間リンクを追加する提案

対象は [ruby/lrama の `master`、`c8317b5`](https://github.com/ruby/lrama/tree/c8317b55850bc6cd9033ddfbf816377b73f6c7bc) です。
この文書は Lrama に投稿する Issue の本文案です。

## 現状

[`Lrama::Diagram#diagrams`](https://github.com/ruby/lrama/blob/c8317b55850bc6cd9033ddfbf816377b73f6c7bc/lib/lrama/diagram.rb) は、`unique_rule_s_values` の定義順に規則を取り出し、同名規則の各選択肢を `Choice` にまとめて SVG を出力しています。
空規則は `Skip`、右辺の終端記号は `Terminal`、非終端記号は `NonTerminal` になります。
非終端記号にはリンクが付いていません。

現行の [`diagram.html`](https://github.com/ruby/lrama/blob/c8317b55850bc6cd9033ddfbf816377b73f6c7bc/template/diagram/diagram.html) は各図の前に `<h2>` を置き、JavaScript が非終端記号の文字列と見出しの文字列を照合してスクロールします。
見出しのアンカー、参照元の一覧、テキスト図はありません。

## 提案

既定の `diagram/diagram.html` を規則間リンク付きのテンプレートに変更します。
`RailroadDiagrams::Document#rule_sections` を使い、通常の `--diagram` と Ruby API の既定出力で規則間リンクと参照元のある SVG を表示します。

Lrama 側の変更点は、規則のまとめ方を再利用する次のメソッドと標準テンプレートです。

```ruby
# Lrama::Diagram の追加メソッド
def linked_sections
  document = RailroadDiagrams::Document.new(title: 'Lrama syntax diagrams', theme: :default)
  action_symbols = @grammar.rules.select(&:original_rule).map(&:lhs)
  @grammar.rules.reject(&:original_rule).group_by { |rule| rule.lhs.id.s_value }.each do |name, rules|
    alternatives = rules.map do |rule|
      diagram_rule = rule.dup
      diagram_rule.rhs = rule.rhs - action_symbols
      diagram_rule.to_diagrams
    end
    document.add_rule(name, RailroadDiagrams::Choice.new(0, *alternatives))
  end
  document.rule_sections
end
```

規則途中のアクション用に生成される補助規則（`$@n`、`@n`）と、その規則への参照を図から除外します。
補助規則は `Rule#original_rule` で判定し、図に使う規則を複製して右辺から補助記号を取り除きます。
ユーザー定義の空規則は残し、パーサー生成に使う元の文法は変更しません。

利用時は `railroad_diagrams` 1.0.0 以降をインストールし、準備・検証済みの文法を渡します。

```ruby
Lrama::Diagram.render(out: out, grammar: grammar)
```

CLI でも通常の `--diagram` を指定します。

```sh
lrama --diagram=diagram.html -o calc.c sample/calc.y
```

`rule_sections` は規則ごとのセクションを定義順に返します。
`svg` 内の定義済み非終端記号には `href="#rule-..."` が付き、`id` は同じ文書の規則アンカーです。
`referenced_by` はその規則を参照する規則名の配列です。
未定義の非終端記号にはリンクを付けません。

標準テンプレートでは `linked_sections` を一度だけ呼び、各規則を `<section id="...">` に入れます。
見出し、SVG、参照元を表示します。
参照元の名前をリンクにする場合は、同じ `sections` から `name → id` の対応を作ります。
名前・ID は HTML の文脈に合わせてエスケープし、生成済みの SVG 断片だけをそのまま挿入します。
文字列照合による既存のクリック処理を削除し、SVG のリンクによる標準のアンカー移動を使います。

## 互換性

- `Lrama::Diagram.render(out:, grammar:)` と `--diagram` の出力を規則間リンク付きの HTML に変更します。
- 構文図の生成には `railroad_diagrams` 1.0.0 以降を使います。
- 補助規則を除いた規則の定義順と、同名規則を `Choice(0, ...)` にまとめる選択肢の順序を保ちます。規則名は `Rule#rhs_to_diagram` と左辺の `s_value` をそのまま使うため、定義済み参照との照合は現在の表示名に従います。
- ページ全体は Lrama の標準テンプレートで描画し、`Document#rule_sections` から各規則の SVG と参照元を受け取ります。

## 確認方法

1. Lrama の `spec/fixtures/common/basic.y` で `Lrama::Diagram.render(out:, grammar:)` を実行し、既定出力に見出し、SVG、規則間リンク、参照元が含まれ、テキスト図が含まれないことを確認します。
2. 同じ文法で `linked_sections` の規則名が、補助規則を除いた元の定義順と一致することを確認します。
3. 全 `id` が一意で、SVG と参照元一覧の `href="#..."` が実在する `id` を指すこと、`unused` のような参照元がない規則と未定義参照に不正なリンクが付かないことを確認します。
4. `program` など参照される規則の `referenced_by` を値で検証します。SVG 断片は REXML で読み、HTML 全体は Lrama で既に使う検証手段で確認します。
5. `--diagram` を使うコマンドのテストでも、規則間リンクと参照元が含まれ、テキスト図が含まれないことを確認します。
6. 値を参照するアクションと参照しないアクションを含む文法で、補助規則の見出し・SVG・リンクが出力されず、ユーザー定義の空規則は残ることを確認します。図の生成前後で元の規則の内容が変わらないことも確認します。
7. Lrama 側の通常の CI で `diagram_spec.rb` と `command_spec.rb` を実行します。
