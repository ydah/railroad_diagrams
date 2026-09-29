# jekyll-railroad

Jekyll の `railroad` コードフェンスから構文図を生成するプラグインの雛形です。フェンスの中身は `railroad_diagrams` の YAML 文法形式で書きます。

## 導入

同梱の `sample/Gemfile` では、両 gem を本リポジトリから読み込みます。

```ruby
gem 'jekyll-railroad', path: '..'
gem 'railroad_diagrams', path: '../../..'
```

`_config.yml` にプラグインを登録します。

```yaml
plugins:
  - jekyll-railroad
```

`sample/` に最小のサイトがあります。リポジトリで 1.0.0 をビルドした後、このディレクトリで `bundle exec jekyll build` を実行できます。

````markdown
```railroad
rules:
  statement:
    - SELECT
    - <table>
  table: name
```
````

各規則は見出し付きの SVG 図になります。
