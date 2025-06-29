import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../theme/app_theme.dart';

class LocationPermissionScreen extends StatelessWidget {
  final VoidCallback onPermissionGranted;

  const LocationPermissionScreen({
    super.key,
    required this.onPermissionGranted,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // アプリロゴ/アイコン
              const Icon(
                Icons.mic, // カラオケのマイクアイコン
                size: 80,
                color: AppTheme.primaryBlue,
              ),

              const SizedBox(height: 24),

              // ウェルカムテキスト
              const Text(
                'からナビへようこそ',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 40),

              // 位置情報アイコン
              const Icon(
                Icons.location_on,
                size: 60,
                color: AppTheme.primaryBlue,
              ),

              const SizedBox(height: 24),

              // 説明テキスト
              const Text(
                'より良いカラオケ店検索のために\n位置情報の使用を許可してください',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 32),

              // メリット説明リスト
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _BenefitItem(
                      icon: Icons.near_me,
                      text: '現在地から近いお店を検索',
                    ),
                    SizedBox(height: 12),
                    _BenefitItem(
                      icon: Icons.access_time,
                      text: '正確な距離・所要時間表示',
                    ),
                    SizedBox(height: 12),
                    _BenefitItem(
                      icon: Icons.directions,
                      text: '最適なルート案内',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // ボタン
              ElevatedButton(
                onPressed: _requestLocationPermission,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  '位置情報を設定する',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // プライバシーに関する一言
              const Text(
                '位置情報は検索のためだけに使用され、サーバーには保存されません',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _requestLocationPermission() async {
    // 位置情報の権限を確認
    LocationPermission permission = await Geolocator.checkPermission();

    // 権限がない場合はリクエスト
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    // 許可・拒否に関わらずホーム画面に遷移
    onPermissionGranted();
  }
}

// メリット項目のウィジェット
class _BenefitItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _BenefitItem({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          color: AppTheme.primaryBlue,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }
}
