import UIKit
import Combine

class FilterOperatorsVC: BaseLogViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        addButton(title: "filter — 过滤偶数")         { [weak self] in self?.demoFilter() }
        addButton(title: "removeDuplicates — 去重")    { [weak self] in self?.demoRemoveDuplicates() }
        addButton(title: "debounce — 防抖(模拟搜索)")   { [weak self] in self?.demoDebounce() }
        addButton(title: "throttle — 节流(快速点击)")   { [weak self] in self?.demoThrottle() }
        addButton(title: "first & last")               { [weak self] in self?.demoFirstLast() }
    }

    private func demoFilter() {
        log("--- filter: 只保留偶数 ---")
        (1...10).publisher
            .filter { $0 % 2 == 0 }
            .sink { [weak self] in self?.log("偶数: \($0)") }
            .store(in: &cancellables)
    }

    private func demoRemoveDuplicates() {
        log("--- removeDuplicates: 移除连续重复值 ---")
        log("输入: [1, 1, 2, 2, 2, 3, 3, 1]")
        [1, 1, 2, 2, 2, 3, 3, 1].publisher
            .removeDuplicates()
            .sink { [weak self] in self?.log("去重后: \($0)") }
            .store(in: &cancellables)
    }

    private func demoDebounce() {
        log("--- debounce: 输入停顿 500ms 后才发出 ---")
        log("模拟快速输入: S → Sw → Swi → Swif → Swift")

        let subject = PassthroughSubject<String, Never>()

        subject
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .sink { [weak self] value in
                self?.log("🔍 debounce 后搜索: \"\(value)\"")
            }
            .store(in: &cancellables)

        let inputs = ["S", "Sw", "Swi", "Swif", "Swift"]
        for (i, text) in inputs.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.1) { [weak self] in
                self?.log("输入: \"\(text)\"")
                subject.send(text)
            }
        }
    }

    private func demoThrottle() {
        log("--- throttle: 500ms 内只取第一个值 ---")

        let subject = PassthroughSubject<Int, Never>()

        subject
            .throttle(for: .milliseconds(500), scheduler: DispatchQueue.main, latest: false)
            .sink { [weak self] in self?.log("✅ throttle 后: \($0)") }
            .store(in: &cancellables)

        for i in 1...10 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.1) { [weak self] in
                self?.log("发送: \(i)")
                subject.send(i)
            }
        }
    }

    private func demoFirstLast() {
        log("--- first & last ---")
        log("输入: [1, 2, 3, 4, 5]")

        [1, 2, 3, 4, 5].publisher
            .first()
            .sink { [weak self] in self?.log("first → \($0)") }
            .store(in: &cancellables)

        [1, 2, 3, 4, 5].publisher
            .last()
            .sink { [weak self] in self?.log("last  → \($0)") }
            .store(in: &cancellables)
    }
}
