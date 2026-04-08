# 第5章：Combine 与 UIKit 集成

> 对应代码：`Chapter5_UIKit/UIKitIntegrationVC.swift`

Combine 不仅仅用于 SwiftUI。在 UIKit 项目中，Combine 可以优雅地替代许多传统模式，让代码更声明式、更易维护。

---

## 5.1 @Published 属性包装器

`@Published` 让普通属性自动具备发布能力。每当属性值改变，会通过 `$` 前缀的 Publisher 发出新值。

```swift
class ViewModel {
    @Published var searchText = ""
}

let vm = ViewModel()
vm.$searchText
    .sink { text in print("新值: \(text)") }
    .store(in: &cancellables)

vm.searchText = "Hello"  // 输出: 新值: Hello
```

### 在 UIKit 中的典型用法

```swift
class SearchVC: UIViewController {
    @Published private var searchText = ""
    private let textField = UITextField()

    func setupBindings() {
        // TextField → @Published（输入方向）
        NotificationCenter.default
            .publisher(for: UITextField.textDidChangeNotification, object: textField)
            .compactMap { ($0.object as? UITextField)?.text }
            .assign(to: &$searchText)

        // @Published → UI（输出方向）
        $searchText
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] text in
                self?.performSearch(text)
            }
            .store(in: &cancellables)
    }
}
```

**注意**：`@Published` 在值改变**之前**（`willSet`）发出新值，而不是改变之后。

---

## 5.2 KVO with Combine

Combine 为所有 `NSObject` 子类的 KVO 兼容属性提供了 `publisher(for:)` 方法。

```swift
let scrollView = UIScrollView()

scrollView.publisher(for: \.contentOffset)
    .sink { offset in
        print("滚动偏移: \(offset)")
    }
    .store(in: &cancellables)
```

### 常用的 KVO 可观察属性

| 类 | 属性 | 说明 |
|----|------|------|
| `UIScrollView` | `\.contentOffset` | 滚动偏移 |
| `UIScrollView` | `\.contentSize` | 内容尺寸 |
| `WKWebView` | `\.estimatedProgress` | 加载进度 |
| `WKWebView` | `\.title` | 页面标题 |
| `AVPlayer` | `\.timeControlStatus` | 播放状态 |
| `URLSessionTask` | `\.progress` | 下载进度 |

### KVO 参数选项

```swift
scrollView.publisher(for: \.contentOffset, options: [.new, .initial])
```

- `.initial`：订阅时立即发出当前值
- `.new`：值改变时发出新值
- `.old`：同时提供旧值（需要用 `NSKeyValueObservedChange`）

---

## 5.3 NotificationCenter with Combine

将 `NotificationCenter` 的通知转为 Publisher。

```swift
// 监听键盘弹出
NotificationCenter.default
    .publisher(for: UIResponder.keyboardWillShowNotification)
    .compactMap { notification -> CGFloat? in
        let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect
        return frame?.height
    }
    .sink { [weak self] height in
        self?.adjustForKeyboard(height: height)
    }
    .store(in: &cancellables)
```

### 常用系统通知

| 通知 | 说明 |
|------|------|
| `UIApplication.didBecomeActiveNotification` | App 变为活跃 |
| `UIApplication.willEnterForegroundNotification` | App 进入前台 |
| `UIApplication.didEnterBackgroundNotification` | App 进入后台 |
| `UITextField.textDidChangeNotification` | 文本框内容变化 |
| `UIResponder.keyboardWillShowNotification` | 键盘即将弹出 |
| `UIResponder.keyboardWillHideNotification` | 键盘即将收起 |

---

## 5.4 Timer.publish

Combine 提供了定时器 Publisher，替代传统的 `Timer.scheduledTimer`。

```swift
Timer.publish(every: 1.0, on: .main, in: .common)
    .autoconnect()  // 自动连接（开始计时）
    .sink { date in
        print("Tick: \(date)")
    }
    .store(in: &cancellables)
```

### autoconnect() 的作用

`Timer.publish` 返回的是 `ConnectablePublisher`，默认不会自动开始发送值。需要调用 `connect()` 或使用 `autoconnect()` 让它在有订阅者时自动开始。

### 停止定时器

```swift
// 方式一：取消订阅
cancellable?.cancel()

// 方式二：清空 cancellables
cancellables.removeAll()
```

---

## 5.5 替代模式对比

| 传统方式 | Combine 方式 | 优势 |
|---------|-------------|------|
| `target-action` + `@objc` | `NotificationCenter.publisher(for: textDidChange)` | 类型安全，可链式处理 |
| `KVO` + `observe(_:)` | `publisher(for: \.property)` | 自动管理生命周期 |
| `NotificationCenter.addObserver` | `NotificationCenter.publisher(for:)` | 无需手动 removeObserver |
| `Timer.scheduledTimer` | `Timer.publish` | 取消更方便，可组合操作符 |
| `Delegate` 协议 | `PassthroughSubject` | 减少协议定义，数据流更清晰 |

> **核心收益**：用 Combine 统一了各种异步/事件机制的 API，所有数据流都可以用相同的操作符进行转换、组合和处理。
