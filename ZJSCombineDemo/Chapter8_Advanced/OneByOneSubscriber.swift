import Combine

/// 每次只请求 1 个值的 Subscriber，收到后再请求下一个
/// 用于演示背压的逐个请求模式
class OneByOneSubscriber: Subscriber {
    typealias Input = Int
    typealias Failure = Never

    private var subscription: Subscription?
    private let logger: (String) -> Void

    init(logger: @escaping (String) -> Void) {
        self.logger = logger
    }

    func receive(subscription: Subscription) {
        self.subscription = subscription
        logger("📩 收到 Subscription")
        logger("📤 request(.max(1)) → 先要 1 个")
        subscription.request(.max(1))
    }

    func receive(_ input: Int) -> Subscribers.Demand {
        logger("📥 收到值: \(input)")
        logger("   处理中... (模拟耗时操作)")
        logger("📤 返回 .max(1) → 再要 1 个")
        logger("")
        return .max(1)  // 每收到 1 个值，再请求 1 个
    }

    func receive(completion: Subscribers.Completion<Never>) {
        logger("✅ 全部完成 (Publisher 没有更多值了)")
        logger("")
        logger("📝 总结: 每次只要 1 个，收到后再要 1 个")
        logger("   这样 Subscriber 永远不会被淹没")
    }
}
