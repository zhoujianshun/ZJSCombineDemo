# 第7章：Combine 与 MVVM 架构

> 对应代码：`Chapter7_MVVM/` 下的 4 个文件

---

## 7.1 为什么 Combine 适合 MVVM？

MVVM（Model-View-ViewModel）的核心是 **数据绑定**——View 和 ViewModel 之间的双向数据流。Combine 天然支持这种模式：

```
┌────────────────────────────────────────────┐
│                   View                      │
│  (UITextField, UIButton, UITableView)       │
│                                             │
│  用户输入 ──────► ViewModel ──────► UI 更新   │
│         (NotificationCenter     (@Published │
│          .publisher)              .sink)    │
└────────────────────────────────────────────┘

┌────────────────────────────────────────────┐
│               ViewModel                     │
│  @Published var username = ""               │
│  @Published var isLoading = false           │
│  @Published var users: [User] = []          │
│                                             │
│  var isFormValid: AnyPublisher<Bool, Never>  │
│  func fetchUsers()                          │
└────────────────────────────────────────────┘

┌────────────────────────────────────────────┐
│                  Model                      │
│  struct User: Codable { ... }               │
│  URLSession.shared.dataTaskPublisher(...)   │
└────────────────────────────────────────────┘
```

---

## 7.2 表单验证实战

> 对应代码：`LoginViewModel.swift` + `LoginViewController.swift`

### ViewModel 设计

ViewModel 用 `@Published` 暴露输入属性，用计算属性暴露验证结果 Publisher：

```swift
class LoginViewModel {
    // Input: View 写入
    @Published var username = ""
    @Published var password = ""
    @Published var confirmPassword = ""

    // Output: View 订阅
    var isUsernameValid: AnyPublisher<Bool, Never> {
        $username.map { $0.count >= 3 }.eraseToAnyPublisher()
    }

    var isFormValid: AnyPublisher<Bool, Never> {
        Publishers.CombineLatest3(
            $username.map { $0.count >= 3 },
            $password.map { $0.count >= 6 },
            Publishers.CombineLatest($password, $confirmPassword)
                .map { $0 == $1 && !$0.isEmpty }
        )
        .map { $0 && $1 && $2 }
        .eraseToAnyPublisher()
    }
}
```

**关键点**：
- `CombineLatest3` 将三个校验条件组合，任一变化都重新计算
- 使用 `eraseToAnyPublisher()` 隐藏复杂的泛型类型
- ViewModel 不依赖 UIKit，可以独立测试

### View 绑定

```swift
class LoginViewController: UIViewController {
    private let viewModel = LoginViewModel()
    private var cancellables = Set<AnyCancellable>()

    func setupBindings() {
        // Input: TextField → ViewModel
        NotificationCenter.default
            .publisher(for: UITextField.textDidChangeNotification, object: usernameField)
            .compactMap { ($0.object as? UITextField)?.text }
            .assign(to: \.username, on: viewModel)
            .store(in: &cancellables)

        // Output: ViewModel → UI
        viewModel.isFormValid
            .receive(on: DispatchQueue.main)
            .sink { [weak self] valid in
                self?.loginButton.isEnabled = valid
                self?.loginButton.backgroundColor = valid ? .systemBlue : .systemGray4
            }
            .store(in: &cancellables)
    }
}
```

### 数据流图

```
usernameField ──text──► $username ──map──► isUsernameValid ──► usernameStatus
passwordField ──text──► $password ──┐
                                    ├── CombineLatest3 ──► isFormValid ──► loginButton
confirmField  ──text──► $confirm ──┘
```

---

## 7.3 列表页实战

> 对应代码：`UserListViewModel.swift` + `UserListViewController.swift`

### ViewModel

```swift
class UserListViewModel {
    @Published var users: [UserItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    func fetchUsers() {
        isLoading = true
        URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: [UserItem].self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] users in
                    self?.users = users
                }
            )
            .store(in: &cancellables)
    }
}
```

### View 绑定三个状态

```swift
// 1. 数据 → 表格
viewModel.$users
    .sink { [weak self] users in
        self?.users = users
        self?.tableView.reloadData()
    }
    .store(in: &cancellables)

// 2. 加载状态 → 指示器
viewModel.$isLoading
    .sink { [weak self] loading in
        loading ? self?.indicator.startAnimating() : self?.indicator.stopAnimating()
    }
    .store(in: &cancellables)

// 3. 错误 → 弹窗
viewModel.$errorMessage
    .compactMap { $0 }  // 过滤 nil
    .sink { [weak self] message in
        self?.showErrorAlert(message)
    }
    .store(in: &cancellables)
```

---

## 7.4 MVVM + Combine 最佳实践

### 1. ViewModel 的 Input/Output 模式

```swift
class ViewModel {
    // === Input（View → ViewModel）===
    @Published var searchText = ""
    func refresh() { ... }

    // === Output（ViewModel → View）===
    @Published private(set) var items: [Item] = []
    @Published private(set) var isLoading = false
}
```

- Input：使用 `@Published` var 或 method
- Output：使用 `@Published private(set)` 或 computed `AnyPublisher`

### 2. 避免在 ViewModel 中引用 View

```swift
// ❌ 错误：ViewModel 依赖 UIKit
class ViewModel {
    var label: UILabel?  // 不应该出现在 ViewModel 中
}

// ✅ 正确：ViewModel 只暴露数据
class ViewModel {
    @Published var displayText = ""  // View 自己订阅并更新 label
}
```

### 3. 使用 [weak self] 防止循环引用

```swift
viewModel.$users
    .sink { [weak self] users in  // 必须 weak self
        self?.updateUI(users)
    }
    .store(in: &cancellables)
```

### 4. ViewModel 可独立测试

```swift
func testFormValidation() {
    let vm = LoginViewModel()
    var isValid = false

    vm.isFormValid
        .sink { isValid = $0 }
        .store(in: &cancellables)

    vm.username = "abc"
    vm.password = "123456"
    vm.confirmPassword = "123456"

    XCTAssertTrue(isValid)
}
```
