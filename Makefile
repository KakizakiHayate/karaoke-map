# Makefile

.PHONY: all run clean get

# デフォルトターゲット
rebuild: clean get run

# 個別コマンド
clean:
	flutter clean

get:
	flutter pub get

run:
	flutter run

analyze:
	flutter analyze

a: analyze

