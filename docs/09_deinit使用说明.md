# deinit 使用说明（结合本项目）

## 1. deinit 是什么

`deinit` 是 Swift 类实例销毁前执行的析构器，用于做“最后清理”。

常见用途：
- 移除通知监听（如果不是 Combine 自动管理）
- 关闭文件句柄/Socket
- 停止定时器、停止外部任务
- 打印释放日志用于排查内存泄漏

注意：
- `deinit` 只会在对象真正释放时调用
- 结构体（`struct`）和枚举（`enum`）没有 `deinit`
- 不能手动调用 `deinit`

---

## 2. 本项目为什么会出现 deinit 报错

本项目启用了：

```text
SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor
```

这会让类型默认带主线程隔离语义。继承链中如果父类 `deinit` 是 MainActor 隔离，而子类 `deinit` 被编译器视为 `nonisolated`，就会报错：

```text
Nonisolated deinitializer 'deinit' has different actor isolation from main actor-isolated overridden declaration
```

---

## 3. 正确写法（推荐）

当类在主线程隔离上下文中使用（尤其是 UIKit 相关类），优先显式写：

```swift
@MainActor
deinit {
    // 清理主线程相关资源
}
```

这样可以避免继承链上隐式隔离推断不一致导致的编译错误。

---

## 4. 继承链里的坑（你遇到的场景）

示例（简化）：

```swift
class A {
    deinit {}
}

class B: A {
    // 这里如果不写 deinit，编译器可能合成与上下文相关的隔离版本
}

class C: B {
    deinit {} // 这里可能触发隔离不一致报错
}
```

### 为什么“注释 B 的 deinit”会影响 C 是否报错？

因为 C 覆盖的目标可能发生变化：
- B 显式写 `deinit`：C 覆盖的是 B 的显式版本
- B 不写 `deinit`：C 可能覆盖编译器为 B 合成的版本（隔离属性可能不同）

解决办法：在 C 上显式标注 `@MainActor deinit`，或统一继承链的析构器隔离策略。

---

## 5. deinit 里应该做什么，不该做什么

### 建议做
- 取消非自动管理的订阅或任务
- 停止外部资源（timer、observer、socket）
- 轻量日志（方便确认对象释放）

### 不建议做
- 复杂业务逻辑
- 依赖异步流程完成的操作
- 访问已经可能无效的外部对象

`deinit` 应保持“短小、幂等、无副作用扩散”。

---

## 6. Combine 场景下的实践建议

如果你用的是：

```swift
private var cancellables = Set<AnyCancellable>()
```

并且订阅都：

```swift
.store(in: &cancellables)
```

通常不需要在 `deinit` 手动 `cancel()`，因为 `cancellables` 随对象释放会自动释放并取消订阅。

可选地保留日志：

```swift
@MainActor
deinit {
    print("BasicsViewController deinit")
}
```

---

## 7. 常见排查清单

出现 deinit 相关并发报错时，按下面顺序检查：

1. 是否启用了 `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`
2. 是否在继承链中覆盖了 `deinit`
3. 子类 `deinit` 是否显式标注 `@MainActor`
4. 是否存在“父类不写、子类写”的合成析构器隔离差异
5. 清理 Xcode 缓存后重新编译（`Clean Build Folder` + 重建）

---

## 8. 推荐模板（可直接用）

```swift
final class SomeViewController: UIViewController {
    private var cancellables = Set<AnyCancellable>()

    @MainActor
    deinit {
        // 通常无需手动 cancel，Set 释放会自动取消
        // 保留释放日志方便排查内存问题
        print("SomeViewController released")
    }
}
```

