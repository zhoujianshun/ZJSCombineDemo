# 第3章：Subject

> 对应代码：`Chapter3_Subjects/SubjectsViewController.swift`

---

## 3.1 什么是 Subject？

Subject 是一种**特殊的 Publisher**，它同时也是 **Subscriber**——你可以从外部手动向它发送值。

普通 Publisher（如 `Just`、`URLSession.dataTaskPublisher`）的值是"内部产生"的，你无法从外部控制。而 Subject 提供了 `send(_:)` 方法，让你可以**命令式地注入值**到响应式管道中。

```
普通 Publisher:  内部产生值 → Operator → Subscriber
Subject:        外部 send() → Operator → Subscriber
```

Subject 是连接**命令式代码**（UIKit 的按钮点击、代理回调等）和**响应式管道**的桥梁。

---

## 3.2 PassthroughSubject

**不保存值**，只有在有订阅者的情况下发送的值才会被接收到。

```swift
let subject = PassthroughSubject<String, Never>()

// 此时没有订阅者，值会丢失
subject.send("Hello")

// 添加订阅者
subject.sink { print($0) }.store(in: &cancellables)

// 现在可以收到了
subject.send("World")  // 输出: World
```

### 特点

- **无初始值**：订阅时不会收到任何值，只有后续 `send()` 的值
- **多播**：多个 Subscriber 都会收到同一个值
- **完成后不可用**：一旦发送 `.finished` 或 `.failure`，后续的 `send()` 全部无效

### 使用场景

- 将 UIKit 的事件（按钮点击、代理回调）转为 Publisher
- 在 ViewModel 中暴露事件流
- 单元测试中模拟数据源

---

## 3.3 CurrentValueSubject

**保存最近一个值**，新的订阅者会**立即收到当前值**。

```swift
let subject = CurrentValueSubject<Int, Never>(0)  // 初始值 = 0

subject.sink { print($0) }.store(in: &cancellables)
// 立即输出: 0

subject.send(1)  // 输出: 1
subject.send(2)  // 输出: 2

print(subject.value)  // 可以直接读取当前值: 2
```

### 特点

- **有初始值**：创建时必须提供初始值
- **可读取 `.value`**：随时通过 `.value` 属性获取当前值（不需要订阅）
- **订阅即发**：新订阅者立即收到当前值

### 使用场景

- 管理状态（如登录状态、加载状态）
- 需要随时读取当前值的场景
- 替代 `@Published`（在非 ObservableObject 的类中）

---

## 3.4 对比

| 特性 | PassthroughSubject | CurrentValueSubject |
|------|-------------------|-------------------|
| 初始值 | 无 | 必须提供 |
| 存储值 | 不存储 | 存储最新值 |
| 新订阅者 | 不收到历史值 | 立即收到当前值 |
| `.value` 属性 | 无 | 有 |
| 类比 | 广播电台（错过就错过） | 公告板（随时可看） |

---

## 3.5 Subject vs @Published

`@Published` 属性包装器内部使用了类似 `CurrentValueSubject` 的机制：

```swift
class ViewModel {
    @Published var name = ""  // 类似 CurrentValueSubject<String, Never>("")
}

// 使用 $ 前缀访问 Publisher
viewModel.$name
    .sink { print($0) }
    .store(in: &cancellables)
```

| 特性 | @Published | CurrentValueSubject |
|------|-----------|-------------------|
| 使用方式 | 属性包装器 | 独立对象 |
| 发送值 | 直接赋值 `name = "new"` | 调用 `send("new")` |
| 读取值 | 直接读取 `name` | 读取 `.value` |
| 发送完成/错误 | 不支持 | 支持 |
| 适用场景 | ViewModel 属性 | 需要完成/错误的场景 |

> **建议**：日常 MVVM 开发优先使用 `@Published`，需要手动发送完成/错误事件时使用 Subject。
