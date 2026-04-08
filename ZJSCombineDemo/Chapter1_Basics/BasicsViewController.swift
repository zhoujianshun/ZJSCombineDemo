import UIKit
import Combine

class BasicsViewController: BaseLogViewController {

    private let assignTarget = AssignTarget()

    override func viewDidLoad() {
        super.viewDidLoad()

        addSectionHeader("— Publisher 类型 —")
        addButton(title: "Just")              { [weak self] in self?.demoJust() }
        addButton(title: "Future")            { [weak self] in self?.demoFuture() }
        addButton(title: "Empty & Fail")      { [weak self] in self?.demoEmptyAndFail() }
        addButton(title: "Deferred")          { [weak self] in self?.demoDeferred() }

        addSectionHeader("— Subscriber 类型 —")
        addButton(title: "sink")              { [weak self] in self?.demoSink() }
        addButton(title: "assign")            { [weak self] in self?.demoAssign() }

        addSectionHeader("— 生命周期 —")
        addButton(title: "AnyCancellable 生命周期") { [weak self] in self?.demoCancellable() }
    }

    // MARK: - Just: 发出单个值后立即完成

    private func demoJust() {
        log("--- Just Demo ---")
        Just(42)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.log("完成: \(completion)")
                },
                receiveValue: { [weak self] value in
                    self?.log("收到值: \(value)")
                }
            )
            .store(in: &cancellables)
    }

    // MARK: - Future: 异步产生单个值

    private func demoFuture() {
        log("--- Future Demo ---")
        log("发起异步操作...")

        Future<String, Never> { promise in
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                promise(.success("异步结果 ✅"))
            }
        }
        .sink(
            receiveCompletion: { [weak self] completion in
                self?.log("完成: \(completion)")
            },
            receiveValue: { [weak self] value in
                self?.log("收到值: \(value)")
            }
        )
        .store(in: &cancellables)
    }

    // MARK: - Empty & Fail

    private func demoEmptyAndFail() {
        log("--- Empty Demo ---")
        Empty<Int, Never>()
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.log("Empty 完成: \(completion) (没有发出任何值)")
                },
                receiveValue: { [weak self] value in
                    self?.log("Empty 值: \(value)")
                }
            )
            .store(in: &cancellables)

        log("--- Fail Demo ---")
        Fail<Int, SampleError>(error: .demo)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.log("Fail 完成: \(completion)")
                },
                receiveValue: { [weak self] value in
                    self?.log("Fail 值: \(value)")
                }
            )
            .store(in: &cancellables)
    }

    // MARK: - Deferred: 每次订阅时才创建 Publisher

    private func demoDeferred() {
        log("--- Deferred Demo ---")
        var count = 0
        let deferred = Deferred {
            count += 1
            return Just("第 \(count) 次订阅时创建")
        }

        deferred
            .sink { [weak self] value in self?.log("订阅者A: \(value)") }
            .store(in: &cancellables)

        deferred
            .sink { [weak self] value in self?.log("订阅者B: \(value)") }
            .store(in: &cancellables)

        log("每次订阅 Deferred 都会重新执行闭包创建 Publisher")
    }

    // MARK: - sink

    private func demoSink() {
        log("--- sink Demo ---")
        [1, 2, 3, 4, 5].publisher
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.log("序列完成: \(completion)")
                },
                receiveValue: { [weak self] value in
                    self?.log("收到: \(value)")
                }
            )
            .store(in: &cancellables)
    }

    // MARK: - assign: 将值直接赋给对象属性

    private func demoAssign() {
        log("--- assign Demo ---")
        log("assign 前: name = \"\(assignTarget.name)\"")

        ["Hello", "Combine", "World"].publisher
            .assign(to: \.name, on: assignTarget)
            .store(in: &cancellables)

        log("assign 后: name = \"\(assignTarget.name)\"")
    }

    // MARK: - AnyCancellable 生命周期

    private func demoCancellable() {
        log("--- AnyCancellable 生命周期 ---")

        let subject = PassthroughSubject<Int, Never>()

        let cancellable = subject
            .sink { [weak self] value in
                self?.log("收到: \(value)")
            }

        subject.send(1)
        subject.send(2)
        log("调用 cancel()...")
        cancellable.cancel()
        subject.send(3)
        log("cancel 后发送的 3 不会被接收到")
    }

}

// MARK: - Helper Types

private enum SampleError: Error, CustomStringConvertible {
    case demo
    var description: String { "示例错误" }
}

private class AssignTarget {
    var name: String = ""
    var title: String = ""
}
