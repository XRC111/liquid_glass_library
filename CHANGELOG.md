# Changelog

All notable changes to this project will be documented in this file.

## [1.0.0] - 2026-10-05

### Added
- `LiquidGlassScene`：背景捕获（RepaintBoundary + toImageSync）、1/4 分辨率可分离高斯模糊链、帧数据分发、自适应捕获降频。
- `LiquidGlassWidget`：SDF 圆角玻璃面板，折射 + RGB 色散 + Fresnel 边缘高光 + 触摸动态光照，脱离场景自动退化。
- `GlassQuality` 三档质量分级（full / medium / minimal）与 `GlassDeviceProfile` 自动设备检测（SDK_INT + isLowRamDevice）。
- `GlassShaderProgram`：FragmentProgram 加载管理（Vulkan + GLSL ES 双后端目标）。
- `GlassFpsOverlay`：帧率验收浮层。
- GLSL 着色器：liquid_glass.frag、blur_horizontal.frag、blur_vertical.frag（含 OpenGL ES Y 轴翻转处理）。
- Example 应用：首页参数调节、玻璃 TabBar、玻璃 AppBar 卡片列表三个演示页。
