import UIKit
import Combine

class SubjectsViewController: BaseLogViewController {

    private let passthroughSubject = PassthroughSubject<String, Never>()
    private let currentValueSubject = CurrentValueSubject<Int, Never>(0)
    private var counter = 0

    override func viewDidLoad() {
        super.viewDidLoad()

        addSectionHeader("— PassthroughSubject —")
        addButton(title: "发送随机字符串") { [weak self] in self?.sendPassthrough() }
        addButton(title: "发送完成事件")  { [weak self] in self?.completePassthrough() }

        addSectionHeader("— CurrentValueSubject —")
        addButton(title: "计数 +1")       { [weak self] in self?.incrementCurrentValue() }
        addButton(title: "读取当前值")     { [weak self] in self?.readCurrentValue() }

        setupSubscriptions()
    }

    private func setupSubscriptions() {
        log("订阅 PassthroughSubject 和 CurrentValueSubject...")

        passthroughSubject
            .sink(
                receiveCompletion: { [weak self] in self?.log("[Passthrough] 完成: \($0)") },
                receiveValue: { [weak self] in self?.log("[Passthrough] 收到: \($0)") }
            )
            .store(in: &cancellables)

        // CurrentValueSubject 订阅时会立即收到当前值
        currentValueSubject
            .sink { [weak self] value in
                self?.log("[CurrentValue] 值 → \(value)")
            }
            .store(in: &cancellables)
    }

    private func sendPassthrough() {
        let words = ["Hello", "Combine", "Swift", "Publisher", "Subscriber", "Operator"]
        let word = words.randomElement()!
        log("发送: \(word)")
        passthroughSubject.send(word)
    }

    private func completePassthrough() {
        passthroughSubject.send(completion: .finished)
        log("⚠️ 已完成，后续 send 将被忽略")
    }

    private func incrementCurrentValue() {
        counter += 1
        currentValueSubject.send(counter)
    }

    private func readCurrentValue() {
        log("直接读取 .value = \(currentValueSubject.value)")
    }
}
