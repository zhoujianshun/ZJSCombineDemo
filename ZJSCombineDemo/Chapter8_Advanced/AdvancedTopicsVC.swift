import UIKit
import Combine

class AdvancedTopicsVC: BaseLogViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        addSectionHeader("— 自定义 Publisher (操作符组合) —")
        addButton(title: "倒计时 Publisher")       { [weak self] in self?.demoCountdown() }
        addButton(title: "自定义 create 风格工厂")  { [weak self] in self?.demoCustomFactory() }

        addSectionHeader("— 背压 (Backpressure) —")
        addButton(title: "sink 默认行为 (unlimited)")  { [weak self] in self?.demoBackpressure() }
        addButton(title: "自定义 Subscriber (逐个请求)") { [weak self] in self?.demoCustomSubscriber() }
        addButton(title: "自定义 Subscriber (批量请求)") { [weak self] in self?.demoBatchSubscriber() }

        addSectionHeader("— Combine ↔ async/await —")
        addButton(title: "Publisher → AsyncSequence") { [weak self] in self?.demoPublisherToAsync() }
        addButton(title: "async → Publisher")         { [weak self] in self?.demoAsyncToPublisher() }

        addSectionHeader("— 类型擦除 —")
        addButton(title: "eraseToAnyPublisher 演示") { [weak self] in self?.demoTypeErasure() }
    }

    // MARK: - 倒计时 Publisher: 用已有操作符组合出复杂行为

    private func demoCountdown() {
        log("--- 倒计时 Publisher ---")
        log("使用 Timer.publish + scan + prefix 组合")

        Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .scan(5) { count, _ in count - 1 }
            .prefix(while: { $0 >= 0 })
            .sink(
                receiveCompletion: { [weak self] _ in
                    self?.log("🎉 倒计时结束!")
                },
                receiveValue: { [weak self] value in
                    self?.log("⏱ \(value)")
                }
            )
            .store(in: &cancellables)
    }

    // MARK: - 自定义工厂: 用 Deferred + Future 模拟 Rx 的 create

    private func demoCustomFactory() {
        log("--- 自定义工厂函数 ---")

        func fetchTemperature(city: String) -> AnyPublisher<(city: String, temp:Double), Never> {
            Deferred {
                Future<(city: String, temp:Double), Never> { promise in
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        let temp = Double.random(in: 15...35)
                        promise(.success((city:city,temp:temp)))
                    }
                }
            }
            .eraseToAnyPublisher()
        }

        fetchTemperature(city: "北京")
            .sink { [weak self] info in
                self?.log("\(info.city)气温: \(String(format: "%.1f", info.temp))°C")
            }
            .store(in: &cancellables)

        fetchTemperature(city: "上海")
            .sink { [weak self] info in
                self?.log("\(info.city)气温: \(String(format: "%.1f", info.temp))°C")
            }
            .store(in: &cancellables)
    }

    // MARK: - 背压演示1: sink 默认请求 unlimited

    private func demoBackpressure() {
        log("=== sink 的默认行为: request unlimited ===")
        log("sink 订阅时会告诉 Publisher: \"把你有的全给我\"")
        log("用 print() 操作符在 Xcode 控制台观察：")
        log("")

        (1...5).publisher
            .print("📊 sink")
            .sink { [weak self] in self?.log("收到: \($0)") }
            .store(in: &cancellables)

        log("")
        log("📝 控制台关键输出:")
        log("  📊 sink: request unlimited    ← 一次请求全部")
        log("  📊 sink: receive value: (1)")
        log("  📊 sink: receive value: (2)")
        log("  ...（一口气收完）")
        log("  📊 sink: receive finished")
    }

    // MARK: - 背压演示2: 自定义 Subscriber 逐个请求

    private func demoCustomSubscriber() {
        log("=== 自定义 Subscriber: 逐个请求 ===")
        log("每次只请求 1 个值，收到后再请求下一个")
        log("")

        let subscriber = OneByOneSubscriber { [weak self] event in
            self?.log(event)
        }
        (1...5).publisher
            .subscribe(subscriber)
    }

    // MARK: - 背压演示3: 自定义 Subscriber 批量请求

    private func demoBatchSubscriber() {
        log("=== 自定义 Subscriber: 每次请求 2 个 ===")
        log("先请求 2 个 → 收完后再请求 2 个 → ...")
        log("")

        let subscriber = BatchSubscriber(batchSize: 2) { [weak self] event in
            self?.log(event)
        }
        (1...7).publisher
            .subscribe(subscriber)
    }

    // MARK: - Publisher → async/await (iOS 15+)

    private func demoPublisherToAsync() {
        log("--- Publisher.values → AsyncSequence ---")

        Task { @MainActor [weak self] in
            for await value in [10, 20, 30, 40, 50].publisher.values {
                self?.log("async for-in: \(value)")
            }
            self?.log("AsyncSequence 遍历完成 ✅")
        }
    }

    // MARK: - async/await → Publisher

    private func demoAsyncToPublisher() {
        log("--- async → Future → Publisher ---")
        log("等待异步结果...")

        func loadDataAsync() async -> String {
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            return "异步加载完成 (1秒后)"
        }

        Deferred {
            Future<String, Never> { promise in
                Task {
                    let result = await loadDataAsync()
                    promise(.success(result))
                }
            }
        }
        .receive(on: DispatchQueue.main)
        .sink { [weak self] value in
            self?.log("收到: \(value)")
        }
        .store(in: &cancellables)
    }

    // MARK: - 类型擦除: eraseToAnyPublisher

    private func demoTypeErasure() {
        log("--- eraseToAnyPublisher ---")
        log("隐藏复杂的泛型类型，暴露简洁的 AnyPublisher")

        func makePublisher(even: Bool) -> AnyPublisher<[Int], Never> {
            if even {
                return (1...10).publisher
                    .filter { $0 % 2 == 0 }
                    .collect()
                    .eraseToAnyPublisher()
            } else {
                return (1...10).publisher
                    .filter { $0 % 2 != 0 }
                    .collect()
                    .eraseToAnyPublisher()
            }
        }

        makePublisher(even: true)
            .sink { [weak self] in self?.log("偶数: \($0)") }
            .store(in: &cancellables)

        makePublisher(even: false)
            .sink { [weak self] in self?.log("奇数: \($0)") }
            .store(in: &cancellables)
    }
}
