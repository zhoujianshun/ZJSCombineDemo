import UIKit
import Combine

class CombineOperatorsVC: BaseLogViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        addButton(title: "merge — 合并多个流")       { [weak self] in self?.demoMerge() }
        addButton(title: "combineLatest — 组合最新值") { [weak self] in self?.demoCombineLatest() }
        addButton(title: "zip — 一一配对")            { [weak self] in self?.demoZip() }
        addButton(title: "switchToLatest — 切换到最新") { [weak self] in self?.demoSwitchToLatest() }
    }

    // MARK: - merge: 将多个 Publisher 的输出合并到一个流

    private func demoMerge() {
        log("--- merge ---")
        let pub1 = PassthroughSubject<String, Never>()
        let pub2 = PassthroughSubject<String, Never>()

        pub1.merge(with: pub2)
            .sink { [weak self] in self?.log("收到: \($0)") }
            .store(in: &cancellables)

        pub1.send("A1")
        pub2.send("B1")
        pub1.send("A2")
        pub2.send("B2")
    }

    // MARK: - combineLatest: 任一源发出新值时，组合所有源的最新值

    private func demoCombineLatest() {
        log("--- combineLatest ---")
        let username = PassthroughSubject<String, Never>()
        let password = PassthroughSubject<String, Never>()

        username.combineLatest(password)
            .sink { [weak self] user, pass in
                self?.log("用户: \(user), 密码: \(pass)")
            }
            .store(in: &cancellables)

        username.send("Alice")
        log("⚠️ 只有 username，不触发 (需要两者都有值)")
        password.send("123")
        username.send("Bob")
        password.send("456")
    }

    // MARK: - zip: 配对两个 Publisher 的值 (一一对应)

    private func demoZip() {
        log("--- zip ---")
        let numbers = [1, 2, 3].publisher
        let letters = ["A", "B", "C", "D"].publisher

        numbers.zip(letters)
            .sink { [weak self] num, letter in
                self?.log("配对: (\(num), \(letter))")
            }
            .store(in: &cancellables)

        log("⚠️ \"D\" 没有配对的数字，不会输出")
    }

    // MARK: - switchToLatest: 订阅最新的内部 Publisher，取消之前的

    private func demoSwitchToLatest() {
        log("--- switchToLatest ---")
        let outer = PassthroughSubject<PassthroughSubject<String, Never>, Never>()
        let inner1 = PassthroughSubject<String, Never>()
        let inner2 = PassthroughSubject<String, Never>()

        outer.switchToLatest()
            .sink { [weak self] in self?.log("收到: \($0)") }
            .store(in: &cancellables)

        outer.send(inner1)
        inner1.send("inner1 - 值1")
        inner1.send("inner1 - 值2")

        log("切换到 inner2 →")
        outer.send(inner2)
        inner1.send("inner1 - 值3 (已切换，不会收到)")
        inner2.send("inner2 - 值1")
    }
}
