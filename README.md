<div align="center">

# liquid_glass_library

**Flutter 液态玻璃（Liquid Glass）组件库 —— 真实折射、RGB 色散、Fresnel 边缘高光**

基于 `FragmentProgram` 自定义片元着色器，覆盖 **Android API 24 → 35**（Impeller Vulkan / OpenGL ES 双后端），低端设备自动降级。

[![Flutter](https://img.shields.io/badge/Flutter-%E2%89%A53.27-02569B?style=flat-square&logo=flutter)](https://flutter.dev/)
[![Platform](https://img.shields.io/badge/Platform-Android%20API%2024%2B-3DDC84?style=flat-square)](#兼容性)
[![License](https://img.shields.io/badge/License-MIT-blue?style=flat-square)](./LICENSE)

</div>

---

> 配套演示程序：[liquid_glass_demo](https://github.com/XRC111/liquid_glass_demo)（完整可运行示例）。
>
> 早期版本（API 不同、已不再更新）：[flutter_liquid_glass](https://github.com/XRC111/flutter_liquid_glass)。

## 特性

| 特性 | 实现 |
| --- | --- |
| **真实折射** | SDF 圆角矩形 + 高度场轮廓 + 中心差分梯度法线，边缘弯曲区产生像素级偏移 |
| **RGB 色散** | R/G/B 三通道以不同折射系数分离采样 |
| **边缘高光** | Fresnel 反射 + 上缘亮线 + 触摸 Blinn-Phong 高光 |
| **可分离高斯模糊** | 水平 + 垂直两趟，在 **1/4 分辨率**离屏缓冲执行（计算量减少约 94%） |
| **五级兼容链** | Vulkan（API 29+）→ OpenGL ES（API 24–28）→ minimal 半透明兜底 |
| **自动分级** | `GlassQuality.full / medium / minimal`，按 `SDK_INT` + `isLowRamDevice` 推导 |
| **微波纹动画** | 时间驱动的轻微流动折射 |

## 安装

```yaml
dependencies:
  liquid_glass_flutter:
    git:
      url: https://github.com/XRC111/liquid_glass_library.git
```

或本地 path 依赖：

```yaml
dependencies:
  liquid_glass_flutter:
    path: ../liquid_glass_library
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
      background: ColorfulBackdrop(),      // 玻璃下方的真实内容
      builder: (context) => Center(
        // LiquidGlassWidget 即玻璃面板，child 绘制在折射效果之上
        child: LiquidGlassWidget(
          borderRadius: 28,
          refraction: 1.0,   // 折射强度
          dispersion: 0.4,   // RGB 色散
          fresnel: 1.0,      // 边缘高光
          animate: true,     // 液态微波纹
          child: const Text('Liquid Glass'),
        ),
      ),
    );
  }
}
```

## API

### `LiquidGlassScene`

场景容器：用 `RepaintBoundary` 包裹 `background`，通过 `RenderRepaintBoundary.toImageSync()` 捕获玻璃下方像素，在 1/4 分辨率离屏缓冲执行可分离高斯模糊，并把帧数据分发给场景内所有玻璃面板。

| 参数 | 说明 |
| --- | --- |
| `background` | 玻璃下方的背景内容（参与折射/模糊） |
| `builder` | 场景内容构建器 |
| `quality` | 手动指定 `GlassQuality`（null 自动检测） |
| `captureScale` | 捕获分辨率系数（默认按档位 0.5 / 0.4 / 0.3） |
| `blurScale` | 模糊缓冲分辨率系数，默认 `0.25` |
| `blurRadius` | 模糊半径（逻辑像素），默认 14 |
| `refreshMode` | `auto`（背景重绘自动重捕获）/ `onDemand`（静态背景最省电） |

### `LiquidGlassWidget`

玻璃面板。脱离 `LiquidGlassScene` 时自动退化为半透明 + 边缘高光，不会崩溃。

| 参数 | 说明 |
| --- | --- |
| `borderRadius` | 圆角半径（SDF 形状） |
| `refraction` | 折射强度，0–1 |
| `dispersion` | RGB 色散强度 |
| `fresnel` | 边缘高光强度 |
| `animate` | 是否启用液态微波纹 |
| `child` | 绘制在玻璃之上的内容 |

### `GlassQuality` / `GlassDeviceProfile`

| 档位 | 设备 | 后端 | 模糊 | 色散 |
| --- | --- | --- | --- | --- |
| `full` | API 29+ | Impeller Vulkan | 1/4 分辨率 | 完整 |
| `medium` | API 26–28 | Impeller OpenGL ES | 1/4 分辨率 | 简化（×0.6） |
| `minimal` | API 24–25 / 低内存 | BackdropFilter 兜底 | 跳过 | 关闭 |

### `GlassFpsOverlay`

调试用帧率浮层，可在示例中开启以观察实际帧率。

## 兼容性

| API | 后端 | 档位 | 预期 |
| --- | --- | --- | --- |
| 33+ | Impeller Vulkan | full | 完整折射 + 色散 + 动态光照，≥30 fps |
| 29–32 | Impeller Vulkan | full | 同上 |
| 26–28 | Impeller OpenGL ES | medium | ≥25 fps，色散/折射略降 |
| 24–25 | Impeller OpenGL ES | minimal | 半透明 + 边缘高光，不崩溃 |
| 低内存设备 | — | minimal | 零离屏模糊缓冲，不 OOM |

- `minimal` 使用 Flutter 内置 `BackdropFilter` + 半透明边框，零离屏缓冲
- 着色器未加载或背景捕获失败时自动回退
- OpenGL ES 后端通过在着色器内 `#if defined(IMPELLER_TARGET_OPENGLES)` 处理纹理 Y 轴翻转

## 性能设计

- 背景捕获与模糊都在降分辨率缓冲上执行（1/4），填充率压力大幅下降
- `onDemand` 模式适合静态背景，避免每帧重捕获
- 帧率不足时自动降频（`full` → `medium` → `minimal`）
- 设备分级是纯逻辑函数，可单测（见 `test/`）

## 项目结构

```
lib/
├── liquid_glass.dart              # 导出入口
├── src/
│   ├── scene.dart                 # LiquidGlassScene
│   ├── widget.dart                # LiquidGlassWidget
│   ├── shader_program.dart        # 着色器加载
│   └── quality.dart               # 设备分级
shaders/
├── liquid_glass.frag
├── blur_horizontal.frag
└── blur_vertical.frag
example/                           # 最小示例
test/
```

## 已知限制

- 仅 Android 端验证（Impeller Vulkan / OpenGL ES）；其他平台未测试
- 极端低端机（API 24 + 低内存）会退化为半透明，没有折射
- 玻璃面板不宜大面积铺满屏幕，建议单个页面不超过 2–3 块

## License

MIT
