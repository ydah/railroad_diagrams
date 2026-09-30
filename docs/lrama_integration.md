# Lrama の構文図に規則間リンクを追加する提案

対象は [ruby/lrama の `master`、`c8317b5`](https://github.com/ruby/lrama/tree/c8317b55850bc6cd9033ddfbf816377b73f6c7bc) です。
この文書は Lrama に投稿する Issue の本文案です。

## 現状

[`Lrama::Diagram#diagrams`](https://github.com/ruby/lrama/blob/c8317b55850bc6cd9033ddfbf816377b73f6c7bc/lib/lrama/diagram.rb) は、`unique_rule_s_values` の定義順に規則を取り出し、同名規則の各選択肢を `Choice` にまとめて SVG を出力しています。
空規則は `Skip`、右辺の終端記号は `Terminal`、非終端記号は `NonTerminal` になります。
非終端記号にはリンクが付いていません。

現行の [`diagram.html`](https://github.com/ruby/lrama/blob/c8317b55850bc6cd9033ddfbf816377b73f6c7bc/template/diagram/diagram.html) は各図の前に `<h2>` を置き、JavaScript が非終端記号の文字列と見出しの文字列を照合してスクロールします。
見出しのアンカー、参照元の一覧、テキスト図はありません。
`Lrama::Diagram.render` は既に `template_name:` を受け取るため、これを任意導入の入口に使えます。

## 提案

既定の `diagram/diagram.html` と `--diagram` の出力は維持します。
追加テンプレート `diagram/linked.html` を `template_name: 'diagram/linked.html'` で明示した場合だけ、`RailroadDiagrams::Document#rule_sections` を使います。
最初は Ruby API から選択できれば十分です。CLI オプションは利用例が確認できた後に検討できます。

Lrama 側の変更点は、規則のまとめ方を再利用する次のメソッドと追加テンプレートです。

```ruby
# Lrama::Diagram の追加メソッド
def linked_sections
  document = RailroadDiagrams::Document.new(title: 'Lrama syntax diagrams', theme: :default)
  @grammar.unique_rule_s_values.each do |name|
    alternatives = @grammar.select_rules_by_s_value(name).map(&:to_diagrams)
    document.add_rule(name, RailroadDiagrams::Choice.new(0, *alternatives))
  end
  document.rule_sections
end
```

利用時は `railroad_diagrams` 1.0.0 以降をインストールし、準備・検証済みの文法を渡します。

```ruby
Lrama::Diagram.render(out: out, grammar: grammar, template_name: 'diagram/linked.html')
```

`rule_sections` は定義順の `{ name:, id:, svg:, text:, referenced_by: }` を返します。
`svg` 内の定義済み非終端記号には `href="#rule-..."` が付き、`id` は同じ文書の規則アンカーです。
`referenced_by` はその規則を参照する規則名の配列、`text` は Unicode のテキスト図です。
未定義の非終端記号にはリンクを付けません。

追加テンプレートでは `linked_sections` を一度だけ呼び、各規則を `<section id="...">` に入れます。
見出し、参照元、`<details><summary>Text diagram</summary><pre>...</pre></details>` を表示します。
参照元の名前をリンクにする場合は、同じ `sections` から `name → id` の対応を作ります。
名前・ID・テキスト図は HTML の文脈に合わせてエスケープし、生成済みの SVG 断片だけをそのまま挿入します。
既存の文字列照合によるクリック処理は追加テンプレートに持ち込まないでください。SVG のリンクによる標準のアンカー移動を使います。

## 互換性

- `Lrama::Diagram.render(out:, grammar:)` と既存の `--diagram` は現行テンプレートを使い、HTML と JavaScript の挙動を変えません。
- 構文図の生成には `railroad_diagrams` 1.0.0 以降を使います。
- 同名規則を `Choice(0, ...)` にまとめる既存の順序を保ちます。規則名は `Rule#rhs_to_diagram` と左辺の `s_value` をそのまま使うため、定義済み参照との照合は現在の表示名に従います。
- `Document#rule_sections` は Lrama のテンプレートを置き換えません。Lrama 固有の CSS、見出し、ページ構成は追加テンプレートで維持できます。

## 確認方法

1. Lrama の `spec/fixtures/common/basic.y` で既存の `Lrama::Diagram.render(out:, grammar:)` を実行し、現在の `diagram_spec.rb` の見出し・SVG の検証に加えて、既定出力が変更前と同じであることを比較します。
2. 同じ文法で追加テンプレートを指定し、`linked_sections` の規則数と定義順が `unique_rule_s_values` と一致することを確認します。
3. 全 `id` が一意で、SVG と参照元一覧の `href="#..."` が実在する `id` を指すこと、`unused` のような参照元がない規則と未定義参照に不正なリンクが付かないことを確認します。
4. `program` など参照される規則の `referenced_by` と `<pre>` 内のテキスト図を値で検証します。SVG 断片は REXML で読み、HTML 全体は Lrama で既に使う検証手段で確認します。
5. Lrama 側の通常の CI で `diagram_spec.rb` を実行し、既定出力と追加テンプレートの出力を検証します。

ローカルでは `railroad_diagrams` 1.0.0 でテストが通り、既定の HTML が変更前とバイト単位で一致することを確認しました。
`common/basic.y` の13規則について、規則間リンク、参照元、テキスト図を検証しています。
