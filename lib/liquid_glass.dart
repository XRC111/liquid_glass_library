/// Liquid Glass for Flutter.
///
/// 真实折射 + RGB 色散 + Fresnel 边缘高光 + 触摸动态光照的玻璃效果组件库，
/// 通过 FragmentProgram 着色器实现，自动覆盖 Android API 24-35：
///
/// * API 29+  : Impeller Vulkan，full 档（全分辨率 + 色散 + 动态光照）
/// * API 26-28: Impeller OpenGL ES，medium 档（1/2 捕获分辨率 + 简化色散）
/// * API 24-25 / 低内存: minimal 档（跳过模糊，仅半透明 + 边缘高光）
///
/// 快速上手：
///
/// ```dart
/// LiquidGlassScene(
///   background: ColorfulBackdrop(),
///   builder: (context) => Center(
///     child: LiquidGlassWidget(
///       borderRadius: 28,
///       refraction: 1.0,
///       dispersion: 0.4,
///       child: const Text('Liquid Glass'),
///     ),
///   ),
/// )
/// ```
library;

export 'src/glass_quality.dart';
export 'src/glass_shader_program.dart';
export 'src/liquid_glass_widget.dart';
export 'src/fps_overlay.dart';
