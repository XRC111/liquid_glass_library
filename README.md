# liquid_glass_flutter

Flutter **液态玻璃（Liquid Glass）**组件库：真实折射、RGB 色散分离、Fresnel 边缘高光、触摸动态光照，基于 `FragmentProgram` 自定义片元着色器，自动覆盖 **Android API 24 → 35**（Impeller Vulkan / OpenGL ES 双后端），低端设备自动降级。

配套演示程序（完整可运行示例）：[liquid_glass_demo](https://github.com/XRC111/liquid_glass_demo)。

## 特性

- **真实折射**：SDF 圆角矩形 + 高度场轮廓 + 中心差分梯度法线，边缘弯曲区产生像素级偏移
- **色散**：R/G/B 三通道分离折射系数采样
- **边缘高光**：Fresnel 反射 + 上缘亮线 + 触摸 Blinn-Phong 高光
- **可分离高斯模糊**：水平 + 垂直两趟，在 **1/4 分辨率**离屏缓冲执行（计算量减少 ~94%）
- **五级兼容链**：Vulkan (API 29+) → OpenGL ES (API 24-28) → minimal 半透明兜底
- **自动分级**：`GlassQuality.full / medium / minimal`，按 `SDK_INT` + `isLowRamDevice` 自动推导，帧率不足时自适应降频

## 安装

```yaml
dependencies:
  liquid_glass_flutter:
    git:
      url: https://github.com/XRC111/liquid_glass_flutter.git
```

或 path 依赖：

```yaml
dependencies:
  liquid_glass_flutter:
    path: ../liquid_glass_flutter
```

着色器资产已随包声明（`packages/liquid_glass_flutter/shaders/*.frag`），使用方无需额外配置。

## 快速上手

```dart
import 'package:flutter/material.dart';
import 'package:liquid_glass_flutter/liquid_glass.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. 预加载着色器（构建期已编译为 Vulkan SPIR-V + GLSL ES 双目标）
  await GlassShaderProgram.load();
  // 2. 设备能力检测 → 自动质量分级
  final profile = await GlassDeviceProfile.detect();

  runApp(MaterialApp(home: DemoPage(profile: profile)));
}

class DemoPage extends StatelessWidget {
  const DemoPage({super.key, required this.profile});

  final GlassDeviceProfile profile;

  @override
  Widget build(BuildContext context) {
    // LiquidGlassScene 负责捕获背景 + 模糊链 + 分发帧数据
    return LiquidGlassScene(
      quality: profile.quality,
      background: ColorfulBackdrop(),          // 玻璃下方的真实内容
      builder: (context) => Center(
        // LiquidGlassWidget 即玻璃面板，child 绘制在折射效果之上
        child: LiquidGlassWidget(
          borderRadius: 28,
          refraction: 1.0,      // 折射强度
          dispersion: 0.4,      // RGB 色散
          fresnel: 1.0,         // 边缘高光
          animate: true,        // 液态微波纹动画
          child: const Text('Liquid Glass'),
        ),
      ),
    );
  }
}
```

## API

### `LiquidGlassScene`

场景容器：用 `RepaintBoundary` 包裹 [background]，通过 `RenderRepaintBoundary.toImageSync()`（`toImage()` 的同步 GPU 变体）捕获玻璃下方像素，在 1/4 分辨率离屏缓冲执行可分离高斯模糊，并把帧数据分发给场景内所有 `LiquidGlassWidget`。

| 参数 | 说明 |
| --- | --- |
| `background` | 位于玻璃下方的背景内容（被捕获参与折射/模糊） |
| `builder` | 场景内容构建器（叠加玻璃面板等 UI） |
| `quality` | 手动指定 `GlassQuality`（null 自动检测） |
| `captureScale` | 捕获分辨率系数（null 按档位默认 0.5/0.4/0.3） |
| `blurScale` | 模糊缓冲分辨率系数，默认 `0.25`（1/4 分辨率） |
| `blurRadius` | 模糊半径（逻辑像素），默认 14 |
| `refreshMode` | `auto`（检测背景重绘自动重捕获）/ `onDemand`（静态背景最省电） |

### `LiquidGlassWidget`

玻璃面板。脱离 `LiquidGlassScene` 时自动退化为半透明 + 边缘高光（不崩溃）。

| 参数 | 说明 |
| --- | --- |
| `borderRadius` | SDF 圆角半径 |
| `refraction` | 折射强度（minimal 档自动减弱） |
| `dispersion` | RGB 色散 0-1（minimal 档强制 0） |
| `fresnel` | Fresnel 边缘高光强度 |
| `opacity` | 整体不透明度（minimal 档默认 0.72 半透明） |
| `animate` | 液态波纹动画开关（false 时仅在触摸/背景变化时重绘） |
| `onTap` | 点击回调 |

### `GlassQuality` / `GlassDeviceProfile`

```dart
enum GlassQuality {
  full,     // API 29+：全分辨率 + 色散 + 动态光照
  medium,   // API 26-28：降采样捕获 + 简化色散
  minimal,  // API 24-25 或低内存：跳过模糊，仅半透明 + 边缘高光
}

static GlassQuality GlassQuality.fromDevice({required int sdkInt, required bool lowRamDevice});
static Future<GlassDeviceProfile> GlassDeviceProfile.detect(); // MethodChannel 检测，结果缓存
```

Android 宿主需上报设备信息（见 example 的 `MainActivity.kt`）：

```kotlin
MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "liquid_glass/device_info")
  .setMethodCallHandler { call, result ->
    if (call.method == "getDeviceInfo") {
      val am = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
      result.success(mapOf("sdkInt" to Build.VERSION.SDK_INT, "lowRam" to am.isLowRamDevice))
    } else result.notImplemented()
  }
```

> 非 Android 平台（iOS/macOS/Windows/Linux）检测不到 SDK 版本时直接使用 `full` 档。

### `GlassFpsOverlay`

内置帧率浮层（`FPS 60 · FULL`），用于性能验收。

## Android 平台要求

```kotlin
// android/app/build.gradle.kts
minSdk = 24      // Flutter 3.35 模板默认
targetSdk = 35
```

```xml
<!-- AndroidManifest.xml -->
<meta-data
    android:name="io.flutter.embedding.android.EnableImpeller"
    android:value="true" />
```

Impeller 优先 Vulkan（依赖 `VK_ANDROID_external_memory_android_hardware_buffer`，API 29+），API 24-28 自动回退 OpenGL ES 2.0。三份 GLSL 着色器统一处理 GLES 后端 Y 轴翻转：

```glsl
vec2 flipIfGles(vec2 uv) {
#if defined(IMPELLER_TARGET_OPENGLES) && !defined(IMPELLER_OPENGLES_UNFLIPPED_DEPRECATED)
  return vec2(uv.x, 1.0 - uv.y);
#else
  return uv;
#endif
}
```

## 降级表现

| API | 后端 | 档位 | 模糊 | 色散 | 目标帧率 |
| --- | --- | --- | --- | --- | --- |
| 29+ | Impeller Vulkan | full | ✅ 1/4 分辨率 | ✅ | ≥ 30fps |
| 26-28 | Impeller OpenGL ES | medium | ✅ 1/4 分辨率 | ⚠️ 简化 | ≥ 25fps |
| 24-25 | Impeller OpenGL ES | minimal | ❌ 跳过 | ❌ | 半透明兜底 |
| 低内存设备 | — | minimal | ❌ 零离屏缓冲 | ❌ | 不 OOM |

## 性能设计

- 模糊 Pass 固定 1/4 分辨率 + 可分离两趟卷积；
- 背景层未重绘时**零捕获开销**（`auto` 模式检测 `RepaintBoundary` 重绘计数）；
- 帧率 < 25fps 自适应降低捕获频率（每 2~4 帧），> 45fps 恢复全速；
- `animate: false` + 静止背景时帧循环自然停止（无空转功耗）；
- 建议玻璃只用于标题栏 / TabBar / 卡片等局部区域。

## License

MIT
