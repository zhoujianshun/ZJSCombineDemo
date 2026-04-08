import UIKit
import Combine

class TransformOperatorsVC: BaseLogViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        addButton(title: "map — 逐个转换")       { [weak self] in self?.demoMap() }
        addButton(title: "flatMap — 转为新 Publisher") { [weak self] in self?.demoFlatMap() }
        addButton(title: "compactMap — 过滤 nil") { [weak self] in self?.demoCompactMap() }
        addButton(title: "scan — 累积计算(每步输出)") { [weak self] in self?.demoScan() }
        addButton(title: "reduce — 累积计算(仅最终)") { [weak self] in self?.demoReduce() }
    }

    private func demoMap() {
        log("--- map: 将每个值 × 10 ---")
        [1, 2, 3, 4, 5].publisher
            .map { $0 * 10 }
            .sink { [weak self] in self?.log("→ \($0)") }
            .store(in: &cancellables)
    }

    private func demoFlatMap() {
        log("--- flatMap: 每个值 → 新 Publisher ---")
        [1, 2, 3].publisher
            .flatMap { value in
                Just("flatMap(\(value)) → \(value * 100)")
            }
            .sink { [weak self] in self?.log($0) }
            .store(in: &cancellables)
    }

    private func demoCompactMap() {
        log("--- compactMap: 尝试转 Int，过滤 nil ---")
        log("输入: [\"1\", \"abc\", \"3\", \"def\", \"5\"]")
        ["1", "abc", "3", "def", "5"].publisher
            .compactMap { Int($0) }
            .sink { [weak self] in self?.log("转换成功: \($0)") }
            .store(in: &cancellables)
    }

    private func demoScan() {
        log("--- scan: 累积求和，每步都输出 ---")
        log("输入: [1, 2, 3, 4, 5]")
        [1, 2, 3, 4, 5].publisher
//            .scan(0) { sum, value in sum + value }
            .scan(0, +)
            .sink { [weak self] in self?.log("累积: \($0)") }
            .store(in: &cancellables)
    }

    private func demoReduce() {
        log("--- reduce: 累积求和，只输出最终结果 ---")
        log("输入: [1, 2, 3, 4, 5]")
        [1, 2, 3, 4, 5].publisher
//            .reduce(0, +)
            .reduce(0, { sum, val in
                sum + val
            })
            .sink { [weak self] in self?.log("结果: \($0)") }
            .store(in: &cancellables)
    }
}
