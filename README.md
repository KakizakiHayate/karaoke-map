# からナビ - カラオケマップアプリ

近くのカラオケ店を簡単に検索できるアプリです。

## 環境構築

このプロジェクトは環境変数を使用しています。以下の手順に従って設定してください。

### 環境変数の設定

1. プロジェクトのルートディレクトリに `.env` ファイルを作成します
2. 以下の内容を追加します：

```
GOOGLE_MAPS_API_KEY=あなたのGoogleMapsAPIキー
```

### iOS向けの設定

iOS向けのビルドでは、`ios/Flutter/Debug.xcconfig` と `ios/Flutter/Release.xcconfig` を編集して環境変数を設定します：

```
#include "Generated.xcconfig"
GOOGLE_MAPS_API_KEY=$(GOOGLE_MAPS_API_KEY)
```

### Android向けの設定

Android向けのビルドでは、環境変数は自動的に `local.properties` から読み込まれます。

## 開発ガイドライン

- APIキーや秘密情報は決して直接コードにハードコードしないでください。常に環境変数を使用してください。
- `.env` ファイルは `.gitignore` に含まれているため、Git リポジトリにコミットされません。

## Flutter の基本情報

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

詳細な Flutter ドキュメントは [オンラインドキュメント](https://docs.flutter.dev/) を参照してください。
