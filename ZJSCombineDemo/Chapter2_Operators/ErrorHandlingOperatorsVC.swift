import UIKit
import Combine

class ErrorHandlingOperatorsVC: BaseLogViewController {

    private enum DemoError: Error, CustomStringConvertible {
        case network
        case parse
        var description: String {
            switch self {
            case .network: return "网络错误"
            case .parse:   return "解析错误"
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        addButton(title: "catch — 捕获错误并替换")   { [weak self] in self?.demoCatch() }
        addButton(title: "retry — 自动重试")          { [weak self] in self?.demoRetry() }
        addButton(title: "replaceError — 用默认值替换") { [weak self] in self?.demoReplaceError() }
        addButton(title: "mapError — 转换错误类型")    { [weak self] in self?.demoMapError() }
    }

    private func demoCatch() {
        log("--- catch: 错误时切换到备用 Publisher ---")
        Fail<String, DemoError>(error: .network)
            .catch { [weak self] error -> Just<String> in
                self?.log("捕获: \(error)，使用默认值")
                return Just("默认数据")
            }
            .sink { [weak self] in self?.log("收到: \($0)") }
            .store(in: &cancellables)
    }

    private func demoRetry() {
        log("--- retry: 失败后自动重试 ---")
        var attempt = 0

        Deferred {
            Future<String, DemoError> { promise in
                attempt += 1
                self.log("第 \(attempt) 次尝试...")
                if attempt < 3 {
                    promise(.failure(.network))
                } else {
                    promise(.success("第 \(attempt) 次成功 ✅"))
                }
            }
        }
        .retry(3)
        .sink(
            receiveCompletion: { [weak self] in self?.log("完成: \($0)") },
            receiveValue: { [weak self] in self?.log("收到: \($0)") }
        )
        .store(in: &cancellables)
    }

    private func demoReplaceError() {
        log("--- replaceError: 用默认值替换错误 ---")
        Fail<Int, DemoError>(error: .parse)
            .replaceError(with: -1)
            .sink { [weak self] in self?.log("替换后的值: \($0)") }
            .store(in: &cancellables)
    }

    private func demoMapError() {
        log("--- mapError: 转换错误类型 ---")
        Fail<String, DemoError>(error: .network)
            .mapError { error -> AppError in
                .general("转换自: \(error)")
            }
            .sink(
                receiveCompletion: { [weak self] in self?.log("mapError 后: \($0)") },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
    }
}

private enum AppError: Error, CustomStringConvertible {
    case general(String)
    var description: String {
        switch self { case .general(let msg): return msg }
    }
}
