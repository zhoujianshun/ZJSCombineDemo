import UIKit
import Combine

class SchedulersViewController: BaseLogViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        addButton(title: "receive(on:) 演示") { [weak self] in self?.demoReceiveOn() }
        addButton(title: "subscribe(on:) 演示") { [weak self] in self?.demoSubscribeOn() }
        addButton(title: "综合: 后台处理 → 主线程更新") { [weak self] in self?.demoCombined() }
    }

    // MARK: - receive(on:): 指定下游在哪个线程接收值

    private func demoReceiveOn() {
        log("--- receive(on:) ---")
        log("在后台 map → receive(on: main) → sink 在主线程")

        [1, 2, 3].publisher
            .subscribe(on: DispatchQueue.global())
            .map { value -> (Int, String) in
                let thread = Thread.isMainThread ? "主线程" : "后台线程"
                return (value * 10, thread)
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value, mapThread in
                let sinkThread = Thread.isMainThread ? "主线程" : "后台线程"
                self?.log("值=\(value), map在[\(mapThread)], sink在[\(sinkThread)]")
            }
            .store(in: &cancellables)
    }

    // MARK: - subscribe(on:): 指定 Publisher 在哪个线程执行订阅

    private func demoSubscribeOn() {
        log("--- subscribe(on:) ---")
        log("subscribe(on: 后台) 让 Publisher 创建逻辑在后台执行")

        Deferred {
            Future<String, Never> { promise in
                let thread = Thread.isMainThread ? "主线程" : "后台线程"
                promise(.success("Future 创建于: \(thread)"))
            }
        }
        .subscribe(on: DispatchQueue.global())
        .receive(on: DispatchQueue.main)
        .sink { [weak self] value in
            self?.log(value)
            self?.log("sink 在: \(Thread.isMainThread ? "主线程" : "后台线程")")
        }
        .store(in: &cancellables)
    }

    // MARK: - 典型模式: 后台处理 → 主线程更新 UI

    private func demoCombined() {
        log("--- 实际场景: 后台耗时处理 → 主线程更新 ---")

        Just("原始数据")
            .subscribe(on: DispatchQueue.global())
            .map { value -> (String, String) in
                Thread.sleep(forTimeInterval: 0.5)
                let thread = Thread.isMainThread ? "主线程" : "后台线程"
                return (value.uppercased(), thread)
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] result, processThread in
                self?.log("处理线程: \(processThread)")
                self?.log("结果: \(result)")
                self?.log("UI更新线程: \(Thread.isMainThread ? "主线程 ✅" : "后台线程 ❌")")
            }
            .store(in: &cancellables)

        log("等待后台处理...")
    }
}
