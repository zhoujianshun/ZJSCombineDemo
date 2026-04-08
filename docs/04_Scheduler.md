# 第4章：Scheduler（调度器）

> 对应代码：`Chapter4_Schedulers/SchedulersViewController.swift`

---

## 4.1 什么是 Scheduler？

Scheduler 定义了**何时**以及在**哪个线程/队列**上执行代码。在 Combine 中，Scheduler 是一个协议，常见的实现有：


| Scheduler                   | 说明                                 |
| --------------------------- | ---------------------------------- |
| `DispatchQueue.main`        | 主线程（UI 更新必须在这里）                    |
| `DispatchQueue.global()`    | 后台并发队列                             |
| `RunLoop.main`              | 主 RunLoop（和 DispatchQueue.main 类似） |
| `ImmediateScheduler.shared` | 当前线程立即执行（不切换线程）                    |


---

## 4.2 两个关键操作符

### receive(on:) ⭐

指定**下游**操作符和 Subscriber 在哪个 Scheduler 上接收值。

```swift
URLSession.shared.dataTaskPublisher(for: url)  // 后台线程
    .map(\.data)                                // 后台线程
    .decode(type: Post.self, decoder: JSONDecoder())  // 后台线程
    .receive(on: DispatchQueue.main)            // ← 从这里开始切到主线程
    .sink { post in
        self.label.text = post.title            // 主线程 ✅
    }
```

**作用位置**：影响 `receive(on:)` **之后**的所有操作符。

### subscribe(on:)

指定**上游** Publisher 的订阅操作和值的生产在哪个 Scheduler 上执行。

```swift
Deferred {
    Future<String, Never> { promise in
        // 这个闭包在后台线程执行
        let result = heavyComputation()
        promise(.success(result))
    }
}
.subscribe(on: DispatchQueue.global())  // ← 让 Future 在后台创建
.receive(on: DispatchQueue.main)        // ← 结果回到主线程
.sink { value in
    self.label.text = value  // 主线程 ✅
}
```

**作用位置**：影响 `subscribe(on:)` **之前**（上游）的操作。

---

## 4.3 图解两者区别

```
subscribe(on:) 影响范围        receive(on:) 影响范围
◄──────────────────────►    ◄──────────────────────►

Publisher → map → filter → receive(on: main) → sink
  ↑                                                ↑
  └── 在后台线程执行                   在主线程执行 ──┘
```

```swift
somePublisher
    .subscribe(on: DispatchQueue.global())  // 上游在后台
    .map { ... }         // 后台
    .filter { ... }      // 后台
    .receive(on: DispatchQueue.main)        // 切换到主线程
    .map { ... }         // 主线程
    .sink { ... }        // 主线程
```

---

## 4.4 实际开发中的典型模式

### 模式一：网络请求 → UI 更新

```swift
URLSession.shared.dataTaskPublisher(for: url)
    .map(\.data)
    .decode(type: [User].self, decoder: JSONDecoder())
    .receive(on: DispatchQueue.main)  // 只需要这一行
    .sink(
        receiveCompletion: { ... },
        receiveValue: { users in
            self.tableView.reloadData()  // 安全地在主线程更新 UI
        }
    )
```

### 模式二：CPU 密集型计算

```swift
Just(largeDataSet)
    .subscribe(on: DispatchQueue.global(qos: .userInitiated))
    .map { data in
        heavyProcessing(data)  // 后台执行耗时计算
    }
    .receive(on: DispatchQueue.main)
    .sink { result in
        self.updateUI(result)  // 主线程更新 UI
    }
```

---

## 4.5 常见陷阱

### 1. 忘记切回主线程

```swift
// ❌ 危险：sink 可能在后台线程执行
URLSession.shared.dataTaskPublisher(for: url)
    .sink { data in
        self.label.text = "..."  // 后台更新 UI → 可能崩溃
    }

// ✅ 正确：显式切回主线程
URLSession.shared.dataTaskPublisher(for: url)
    .receive(on: DispatchQueue.main)
PassthroughSubject    .sink { data in
        self.label.text = "..."  // 主线程 ✅
    }
```

### 2. subscribe(on:) 的位置不影响效果

`subscribe(on:)` 无论放在管道的哪个位置，效果都是一样的（影响整个上游）：

```swift
// 以下两种写法效果相同
publisher.subscribe(on: DispatchQueue.global()).map { ... }
publisher.map { ... }.subscribe(on: DispatchQueue.global())
```

### 3. receive(on:) 的位置很重要

`receive(on:)` 只影响**它之后**的操作符：

```swift
publisher
    .map { ... }                        // 原始线程
    .receive(on: DispatchQueue.main)    // ← 切换点
    .filter { ... }                     // 主线程
    .sink { ... }                       // 主线程
```

---

## 4.6 总结


| 操作符              | 影响方向 | 影响范围                 | 常见用法        |
| ---------------- | ---- | -------------------- | ----------- |
| `receive(on:)`   | 下游   | 之后所有操作符 + Subscriber | UI 更新前切到主线程 |
| `subscribe(on:)` | 上游   | Publisher 的创建和值的生产   | 让耗时操作在后台执行  |


> **实践经验**：90% 的场景只需要 `receive(on: DispatchQueue.main)` 一行。`subscribe(on:)` 较少使用，除非需要显式控制 Publisher 的创建线程。

