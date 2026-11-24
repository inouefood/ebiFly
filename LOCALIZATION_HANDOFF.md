# ローカライズ引き継ぎメモ

ブランチ: `feature/Localize`（未コミット）
開発言語は `ja`。String Catalog を使用。

## これまでにやったこと

### コード
- 素の `String` として流れていた日本語リテラルを `String(localized: "…")` で包んだ（モデルの `displayName`、SpriteKit の `SKLabelNode`、`Toast` / `Pill` / `OutlinedText` / `FinishOverlay` などの引数）。
  `Text("…")` / `Button("…")` / `.accessibilityLabel("…")` に直接渡しているリテラルは、もともとローカライズされるので触っていない。
- `ItemTrial.discountLabel`（`ebiFly/Views/ItemViews.swift`）を `String(localized: "\(…)pt")` に変更し、既存キー `%@pt` を使い回すようにした。
- `OutlinedText`（`ebiFly/App/Theme.swift`）の `.fixedSize()` をやめて `.lineLimit(1).minimumScaleFactor(0.4).fixedSize(horizontal: false, vertical: true)` にした。長い翻訳（タイトルロゴなど）でも画面からはみ出さず縮む。収まる場合の見た目は前と同じ。

### プロジェクト
- `knownRegions` に 50 言語を追加済み（下の一覧。fa は追加していない）。
- String Catalog は次の 2 つ:
  - `ebiFly/Localizable.xcstrings`（181 キー）
  - `ebiFly/ebiFly-InfoPlist.xcstrings`（`CFBundleDisplayName`, `CFBundleName`, `NSUserTrackingUsageDescription`）

## 言語ごとの状況

| 状況 | 言語 |
|---|---|
| 完了（184/184、32 言語） | en, zh-Hans, zh-Hant, ko, es, es-419, pt-BR, pt-PT, fr, it, de, nl, ru, uk, pl, cs, sk, hu, ro, hr, sl, bg, el, tr, sv, da, nb, fi, ca, he, ar, hi |
| 未着手（18 言語、knownRegions には追加済み） | th, vi, id, ms, fil, bn, ta, te, mr, gu, kn, ml, pa, ur, kk, lt, lv, et |
| 対象外 | fa（主な市場のイランで AdMob の広告を配信できないため） |

### 残っている修正
- `%lldパーセント` の 12 言語（de, en, es, es-419, fr, it, ko, nl, pt-BR, pt-PT, zh-Hans, zh-Hant）が `needs_review`。
  途中で ja ソースに plural（zero/other）が追加されたため、Xcode が自動で plural 構造に移行し、one/zero が needs_review になった。
  値自体は正しいので、各言語に必要な plural カテゴリ（例: en は one/other）をそろえて state を `translated` にすればよい。

## 未着手の言語を翻訳するとき

### String Catalog の形式
- Xcode の MCP ツールを使えない場合は `.xcstrings`（JSON）を直接編集してよい。
- 編集後は Xcode でビルドし、カタログが壊れていないか確認する（Xcode がフォーマットを整え直す）。
- 単純な値:
  ```json
  "th": { "stringUnit": { "state": "translated", "value": "…" } }
  ```
- plural がある場合は `variations.plural.<category>.stringUnit` を使う。カテゴリは CLDR に従う。
  - 例: ru は one/few/many/other、ar は zero/one/two/few/many/other。
  - th, vi, id, ms のように数で語形が変わらない言語は other だけ（zero があれば同じ文）でよい。
  - 既存の ru / ar を参考にするとよい。
- iPhone という語を含む 2 キー（`iPhoneをかたむけてよけよう`, `iPhoneをふって%@をかけよう`）は、他の言語に合わせて `variations.device`（iphone / ipad / other）を付ける。
- **ja のソースエントリは変更しないこと。** 変更すると全言語が needs_review になる。
- `\n` は ja ソースにある場合だけ使う。
- `&amp;` などのエンティティは使わない（`&` はそのまま書く）。
- 引用符はその言語の正しいもの（“…”、«…»、„…“ など）を使う。

### 翻訳方針（ブリーフ）
アプリは「とべ！えびフライ」。子ども向けのカジュアルなミニゲーム。
流れは次のとおり:
1. えびを作る（しっぽ、からだの長さ）
2. 衣をつける（パン粉キャッチ）
3. 揚げる（きつね色で止める）
4. ソースをかける（iPhone をシェイク）
5. 空へ発射し、鳥・飛行機・いん石をよけながら、ソースのボトルで燃料を補給する

距離に応じてポイント（pt）がたまり、ショップで見た目のアイテムと交換できる。リワード広告でつづきから飛べたり、割引を受けられたりする。

- **トーン**: やさしく短く、子どもにわかる語で。二人称の区別がある言語はくだけた形（du/tu/ты など）を使う。
- **長さ**: ボタン、HUD、トーストが多いので、日本語と同じくらい短くする。アイテム名は 1〜2 語。
- **アプリ名**:
  - `CFBundleDisplayName`、`CFBundleName`、タイトルロゴ（キー `えびフライ`）は、その言語で「えびフライ（フライドシュリンプ）」を表す短く自然な名前にする（できれば 12 文字以内）。
  - en は "Ebi Fry"、ko は 새우튀김、zh-Hans は 炸虾。
  - タイトル上の「とべ！」は "Fly!"。
- **用語**:
  - pt はそのまま。m と m/s もそのまま。iPhone もそのまま。
  - 衣 / ころも = 衣の工程・カテゴリ、パン粉 = panko、きつね色 = 完璧な揚げ色、なま = 生、こげ = こげ。
  - ステップバー: つくる / 衣 / 揚げる / ソース / とばす
  - ソースの強さ（弱い順）: ちょろちょろ < ぐんぐん < びゅーん < ロケット。「マヨ びゅーん」のように表示される。
  - マヨ / ケチャ は HUD 用の短縮名。短縮すると誤解される言語では、元の名前のままでよい。
  - ランク（距離順）: 生えび → 見習いフライ → きつね色フライ → 雲ごえフライ → 成層圏フライ → 宇宙えびフライ
  - 擬音（ポーン！、びしょっ）は、その言語の自然な擬音にする。
- **シェイクのカウンター**:
  - 単独キー `回` は [シェイク] [大きな数字] [回] と 3 つに分かれて表示され、複数形にできない。
  - そのため `回` は "×" のように数を選ばない記号にし、`シェイク` はラベルとして訳す（例 "Shakes"）。
- **障害物の文**:
  - 鳥 / 飛行機 / いん石 は `%@にぶつかった(！)` の中でしか使われない。
  - 3 つとも文法的に合うように文を組む（冠詞を名前側に含める、"Crash: %@" のようにする、など）。
- **語形変化する言語**: `%@` に入るアイテム名は基本形のまま入るので、「ソース: %@」のように格変化が起きない形にする。
- **数**: 名詞が後に続く数は、必要な plural をすべて埋める。
- **記号だけの文字列**: `%lld`、`%@m`、`?`、`・`、`m`、`pt`、`%lld/%lld`、`%@  %lld/%lld`、`+%@pt` は基本そのままでよい（RTL や単位前のスペースは調整してよい）。
- **ATT 文言**（`NSUserTrackingUsageDescription`）: "Used to show ads that are relevant to you." を自然で丁寧な文にする。

### RTL / 特殊な文字
- ar / he / ur は RTL。書式指定子はそのまま残し、pt / m / iPhone はラテン文字のまま。
- フォント（Dela Gothic One / Zen Maru Gothic）にない文字（タイ文字、デーヴァナーガリー文字、アラビア文字など）は、iOS のシステムフォントで表示される。実機で見た目を確認すること。

## 残りの確認
- 実機またはシミュレータで、長い言語（de, nl, fr, pl など）のタイトル、ステップバー、ボタンを確認する。
- 機械翻訳の状態なので、主要な言語はネイティブのレビューを入れるとよい。
- App Store のメタデータ（説明文、スクリーンショット）と Game Center のリーダーボード名はまだローカライズしていない。
