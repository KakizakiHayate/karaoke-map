import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../app_state.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _appVersion = '';
  bool _isLoading = true;
  int _titleTapCount = 0; // タイトルがタップされた回数
  static const int _requiredTapCount = 5; // デバッグモード表示に必要なタップ回数
  static const String _debugPassword = 'karaoke123'; // デバッグモード用パスワード

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
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

  // タイトルがタップされたときの処理
  void _handleTitleTap() {
    setState(() {
      _titleTapCount++;
    });

    // 5回タップされたらパスワードダイアログを表示
    if (_titleTapCount == _requiredTapCount) {
      _showPasswordDialog();
      // カウントをリセット
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _titleTapCount = 0;
          });
        }
      });
    }
  }

  // パスワード入力ダイアログを表示
  void _showPasswordDialog() {
    final TextEditingController passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('デバッグモード'),
          content: TextField(
            controller: passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              hintText: 'パスワードを入力',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () {
                if (passwordController.text == _debugPassword) {
                  // デバッグモードを有効化
                  Provider.of<AppState>(context, listen: false)
                      .toggleDebugMode(true);
                  Navigator.of(context).pop();

                  // 成功メッセージを表示
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('デバッグモードが有効になりました'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 2),
                    ),
                  );
                } else {
                  // エラーメッセージを表示
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('パスワードが正しくありません'),
                      backgroundColor: AppTheme.primaryRed,
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
              ),
              child: const Text('確認'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDebugMode = Provider.of<AppState>(context).isDebugMode;

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: _handleTitleTap,
          child: const Text(
            '設定',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
            ),
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

                // デバッグモードが有効の場合のみデバッグセクションを表示
                if (isDebugMode) ...[
                  _buildSectionHeader('デバッグ'),

                  // デバッグモード無効化
                  ListTile(
                    leading: const Icon(Icons.bug_report, color: Colors.red),
                    title: const Text('デバッグモードを無効化'),
                    onTap: () {
                      Provider.of<AppState>(context, listen: false)
                          .toggleDebugMode(false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('デバッグモードを無効化しました'),
                          backgroundColor: Colors.green,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
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
