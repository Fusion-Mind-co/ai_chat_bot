// lib/theme/borders.dart
import 'package:flutter/material.dart';

// RoundedRectangleBorderを継承して独自のボーダースタイルを作成
class GradientBorder extends RoundedRectangleBorder {
  // コンストラクタ：必要なパラメータを定義
  const GradientBorder({
    required this.gradient,  // グラデーションの設定
    required BorderRadiusGeometry borderRadius,  // 角の丸み
    required this.width,  // ボーダーの太さ
  }) : super(borderRadius: borderRadius);

  final Gradient gradient;
  final double width;

  // ウィジェットのサイズが変更されたときの挙動を定義
  @override
  ShapeBorder scale(double t) {
    return GradientBorder(
      gradient: gradient,
      borderRadius: borderRadius * t,
      width: width * t,
    );
  }

  // ウィジェットの状態が変更されたときのコピー動作を定義
  @override
  RoundedRectangleBorder copyWith({
    BorderSide? side,
    BorderRadiusGeometry? borderRadius,
  }) {
    return GradientBorder(
      gradient: gradient,
      borderRadius: borderRadius ?? this.borderRadius,
      width: width,
    );
  }

  // ボーダーの外側のパスを定義
  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..addRRect(borderRadius.resolve(textDirection).toRRect(rect));
  }

  // 実際の描画処理
  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    // 角丸の矩形を作成
    final RRect outer = borderRadius.resolve(textDirection).toRRect(rect);
    
    // 描画設定
    final Paint paint = Paint()
      ..shader = gradient.createShader(rect)  // グラデーションを適用
      ..strokeWidth = width  // 線の太さ
      ..style = PaintingStyle.stroke;  // 塗りつぶしではなく線として描画
    
    // 実際の描画
    canvas.drawRRect(outer, paint);
  }
}