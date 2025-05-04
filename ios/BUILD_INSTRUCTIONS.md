# iOSビルド手順

## 前提条件
- Macコンピュータ
- Xcodeがインストールされていること
- Apple Developer Programへの登録
- 有効な証明書とプロビジョニングプロファイル

## App Store向けipaファイルのビルド手順

### 1. バンドルIDの設定
Xcodeでプロジェクトを開き、`Runner`ターゲットの設定画面で適切なバンドルIDを設定します：

```
open ios/Runner.xcworkspace
```

### 2. 証明書とプロビジョニングプロファイルの設定
Xcodeの「Signing & Capabilities」タブで、Apple Developer Accountにログインし、適切なチームを選択します。

### 3. アーカイブとipaの作成
#### 方法1: Xcodeから
1. Xcodeで「Product」→「Archive」を選択
2. アーカイブが完了したら「Distribute App」を選択
3. App Store Connectへのアップロード、またはipaファイルのエクスポートを選択

#### 方法2: コマンドラインから
プロビジョニングプロファイルと証明書が設定済みの場合：

```bash
flutter build ipa
```

または、自動署名を使用する場合：

```bash
flutter build ipa --export-options-plist=ios/ExportOptions.plist
```

ビルドされたipaファイルは `build/ios/ipa/` ディレクトリに保存されます。

### 4. ExportOptions.plistの設定
このファイルは `ios/ExportOptions.plist` にあり、以下の項目を適切に設定する必要があります：

- `method`: "app-store"（App Store用）または "ad-hoc"（テスト用）
- `teamID`: あなたのApple Developer TeamのID
- `signingStyle`: "automatic"（推奨）または "manual"
- `provisioningProfiles`: バンドルIDとプロファイル名の対応

### 5. fastlaneを使ったビルド（オプション）
fastlaneがインストールされている場合：

```bash
cd ios
bundle exec fastlane build_ipa
```

## トラブルシューティング

### ビルドエラー
1. Podfileの依存関係エラー：`pod install`を実行
2. 証明書エラー：Xcodeでキーチェーンアクセスの証明書を確認
3. プロビジョニングプロファイルエラー：Apple Developer Portalで有効なプロファイルを作成

### ipaファイル生成後
TestFlightやApp Store Connectにアップロードする前に以下を確認：
- アプリアイコンが正しく設定されていること
- アプリバージョンとビルド番号が適切に設定されていること
- 必要なアクセス許可がInfo.plistに記述されていること 