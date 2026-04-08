# ZJSCombineDemo

一个基于 UIKit 的 Combine 学习项目，按章节组织，从基础到实战逐步推进。  
项目目标是：**每个知识点都能运行、可观察、可修改、可验证**。

## 项目特点

- 使用原生 `Combine` + `UIKit`，不依赖第三方响应式库
- 按 8 个章节组织代码，覆盖从入门到进阶的核心能力
- 每个章节提供可点击的 Demo 按钮和日志输出，方便观察数据流
- 提供配套中文文档，解释概念、常见坑和实践建议

## 运行环境

- Xcode 26+
- iOS Simulator（推荐 iPhone 17 Pro 或任意可用模拟器）
- Swift Concurrency 配置：
  - `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`
  - 项目当前已适配该配置下的 `deinit` 隔离问题

## 如何运行

1. 打开 `ZJSCombineDemo.xcodeproj`
2. 选择 Scheme：`ZJSCombineDemo`
3. 选择模拟器并运行
4. 进入首页 `Combine 学习`，按章节点击进入 Demo

## 学习路径（建议顺序）

1. 第1章：基础概念（Publisher / Subscriber / AnyCancellable）
2. 第2章：操作符（转换、过滤、组合、错误处理）
3. 第3章：Subject（PassthroughSubject / CurrentValueSubject）
4. 第4章：Scheduler（`receive(on:)` / `subscribe(on:)`）
5. 第5章：UIKit 集成（`@Published`、KVO、NotificationCenter、Timer）
6. 第6章：网络请求（`dataTaskPublisher`、`decode`、`retry`、链式请求）
7. 第7章：MVVM 实战（表单验证、列表页绑定）
8. 第8章：高级主题（背压、类型擦除、Combine ↔ async/await）

## 代码结构

```text
ZJSCombineDemo/
├── Common/
│   └── BaseLogViewController.swift
├── Main/
│   └── ChapterListViewController.swift
├── Chapter1_Basics/
├── Chapter2_Operators/
├── Chapter3_Subjects/
├── Chapter4_Schedulers/
├── Chapter5_UIKit/
├── Chapter6_Networking/
├── Chapter7_MVVM/
└── Chapter8_Advanced/
```

## 文档索引

文档位于 `docs/`：

- `00_学习大纲.md`
- `01_基础概念.md`
- `02_操作符.md`
- `03_Subject.md`
- `04_Scheduler.md`
- `05_UIKit集成.md`
- `06_网络请求.md`
- `07_MVVM架构.md`
- `08_高级主题.md`
- `09_deinit使用说明.md`

## 特别说明：deinit 与 MainActor

项目启用了 `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`，在继承链中重写 `deinit` 时可能出现隔离不一致错误。  
建议在需要的类中显式使用：

```swift
@MainActor
deinit {
    // 清理主线程资源
}
```

详细说明见 `docs/09_deinit使用说明.md`。

## 学习建议

- 每次只看一个按钮对应的一段逻辑，跑完后再改参数验证
- 关注 `print()` 和页面日志输出，理解事件流顺序
- 重点掌握：
  - `debounce` vs `throttle`
  - `combineLatest` vs `zip`
  - `flatMap` vs `map`
  - `store(in:)` 与生命周期管理

## 后续可扩展方向

- 增加单元测试（对 ViewModel 与 Operator 链做可重复验证）
- 增加 SwiftUI 版本对照
- 增加真实业务 API（带鉴权、分页、缓存）

