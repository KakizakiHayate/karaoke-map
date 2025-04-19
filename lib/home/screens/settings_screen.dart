import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../theme/app_theme.dart';
import '../../services/review_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _appVersion = '';
  bool _isLoading = true;
  int _searchCount = 0;
  final ReviewService _reviewService = ReviewService();

  // 開発者メニューの表示状態
  bool _showDeveloperMenu = false;

  // タップカウンターを追加（7回タップで開発者メニューを表示）
  int _versionTapCount = 0;

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
    _loadSearchCount();
  }

  Future<void> _loadAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _appVersion = '${packageInfo.version} (${packageInfo.buildNumber})';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _appVersion = '取得できませんでした';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadSearchCount() async {
    final count = await _reviewService.getSearchCount();
    setState(() {
      _searchCount = count;
    });
  }

  void _onVersionTap() {
    _versionTapCount++;
    if (_versionTapCount >= 7) {
      setState(() {
        _showDeveloperMenu = !_showDeveloperMenu;
        _versionTapCount = 0;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(_showDeveloperMenu ? '開発者モードを有効化しました' : '開発者モードを無効化しました'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _resetSearchCount() async {
    await _reviewService.resetSearchCount();
    await _loadSearchCount();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('検索回数をリセットしました'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _showAppReview() async {
    await _reviewService.forceRequestReview();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '設定',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                // 情報セクション
                _buildSectionHeader('情報'),

                // アプリバージョン
                ListTile(
                  leading: const Icon(Icons.info_outline,
                      color: AppTheme.primaryBlue),
                  title: const Text('アプリバージョン'),
                  subtitle: Text(_appVersion),
                  onTap: _onVersionTap,
                ),

                // プライバシーポリシー
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined,
                      color: AppTheme.primaryBlue),
                  title: const Text('プライバシーポリシー'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _showPrivacyPolicy(context),
                ),

                // 利用規約
                ListTile(
                  leading: const Icon(Icons.description_outlined,
                      color: AppTheme.primaryBlue),
                  title: const Text('利用規約'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _showTermsOfService(context),
                ),

                // お問い合わせ
                ListTile(
                  leading: const Icon(Icons.mail_outline,
                      color: AppTheme.primaryBlue),
                  title: const Text('お問い合わせ'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _contactUs(),
                ),

                // 開発者メニュー（隠し機能）
                if (_showDeveloperMenu) ...[
                  _buildSectionHeader('開発者メニュー'),

                  // 検索回数表示
                  ListTile(
                    leading: const Icon(Icons.search, color: Colors.orange),
                    title: const Text('現在の検索回数'),
                    subtitle: Text('$_searchCount回'),
                    trailing: IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: _loadSearchCount,
                    ),
                  ),

                  // 検索回数リセット
                  ListTile(
                    leading:
                        const Icon(Icons.delete_forever, color: Colors.red),
                    title: const Text('検索回数をリセット'),
                    onTap: _resetSearchCount,
                  ),

                  // レビューダイアログ表示テスト
                  ListTile(
                    leading: const Icon(Icons.star, color: Colors.amber),
                    title: const Text('レビューダイアログをテスト表示'),
                    onTap: _showAppReview,
                  ),
                ],
              ],
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }

  void _showPrivacyPolicy(BuildContext context) {
    final Uri privacyPolicyUrl = Uri.parse(
        'https://docs.google.com/document/d/1OuhczxYHmCCt4jpwhDyXRWWbD_c_Ta-cKd2UTFDrfxA/edit?usp=sharing');
    launchUrl(privacyPolicyUrl, mode: LaunchMode.externalApplication);
  }

  void _showTermsOfService(BuildContext context) {
    final Uri termsOfServiceUrl = Uri.parse(
        'https://docs.google.com/document/d/1e2q04fqh7Esg-vlBc1WkkpKiZReyUpSv8o2HrEwolS4/edit?usp=sharing');
    launchUrl(termsOfServiceUrl, mode: LaunchMode.externalApplication);
  }

  Future<void> _contactUs() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'hayate.kakizaki@gmail.com',
      query: 'subject=カラオケマップに関するお問い合わせ',
    );

    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('メールアプリを開けませんでした。'),
            backgroundColor: AppTheme.primaryRed,
          ),
        );
      }
    }
  }
}

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('プライバシーポリシー'),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'プライバシーポリシー',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Text(
              '当アプリケーション「カラオケマップ」（以下、「当アプリ」）は、ユーザーのプライバシーを尊重し、個人情報の保護に努めています。本ポリシーでは、当アプリが収集する情報とその利用方法について説明します。',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 16),
            Text(
              '1. 収集する情報',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '当アプリは、以下の情報を収集することがあります：\n'
              '• 位置情報：ユーザーの現在地を基にカラオケ店を検索するために使用します\n'
              '• 検索履歴：ユーザーの利便性向上のために保存します\n'
              '• 保存済み場所：ユーザーがお気に入りとして保存した場所を記録します',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 16),
            Text(
              '2. 情報の利用目的',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '収集した情報は以下の目的で利用します：\n'
              '• カラオケ店の検索機能の提供\n'
              '• アプリの機能改善\n'
              '• ユーザー体験の向上',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 16),
            Text(
              '3. 第三者への提供',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '当アプリは、法律で定められた場合を除き、ユーザーの同意なく第三者に個人情報を提供することはありません。',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 16),
            Text(
              '4. データの保管',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'ユーザーデータは主にデバイス内に保存され、クラウドサーバーには送信されません。',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 16),
            Text(
              '5. お問い合わせ',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'プライバシーポリシーに関するご質問やお問い合わせは、hayate.kakizaki@gmail.com までご連絡ください。',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 16),
            Text(
              '最終更新日：2024年4月6日',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('利用規約'),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '利用規約',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'この利用規約（以下、「本規約」）は、カラオケマップアプリ（以下、「当アプリ」）の利用条件を定めるものです。ユーザーの皆様は、本規約に同意の上、当アプリをご利用ください。',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 16),
            Text(
              '1. 適用',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '本規約は、ユーザーと当アプリ運営者との間の当アプリの利用に関わる一切の関係に適用されます。',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 16),
            Text(
              '2. 禁止事項',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'ユーザーは、当アプリの利用にあたり、以下の行為をしてはなりません：\n\n'
              '• 法令または公序良俗に違反する行為\n'
              '• 犯罪行為に関連する行為\n'
              '• 当アプリの運営を妨害する行為\n'
              '• 他のユーザーに不利益を与える行為\n'
              '• その他、当アプリ運営者が不適切と判断する行為',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 16),
            Text(
              '3. 免責事項',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '当アプリ運営者は、当アプリで提供する情報の正確性や完全性を保証するものではありません。また、当アプリの利用によって生じたいかなる損害についても責任を負いません。',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 16),
            Text(
              '4. 規約の変更',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '当アプリ運営者は、必要と判断した場合には、ユーザーに通知することなく本規約を変更することがあります。',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 16),
            Text(
              '5. 準拠法と管轄裁判所',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '本規約の解釈にあたっては、日本法を準拠法とします。また、当アプリに関連する紛争については、東京地方裁判所を第一審の専属的合意管轄裁判所とします。',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 16),
            Text(
              '最終更新日：2024年4月6日',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
