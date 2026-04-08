import Combine

/// 分批请求值的 Subscriber，每次请求固定数量
/// 用于演示背压的批量请求模式
class BatchSubscriber: Subscriber {
    typealias Input = Int
    typealias Failure = Never

    private var subscription: Subscription?
    private let batchSize: Int
    private var receivedInBatch = 0
    private var totalReceived = 0
    private let logger: (String) -> Void

    init(batchSize: Int, logger: @escaping (String) -> Void) {
        self.batchSize = batchSize
        self.logger = logger
    }

    func receive(subscription: Subscription) {
        self.subscription = subscription
        logger("📩 收到 Subscription")
        logger("📤 request(.max(\(batchSize))) → 第1批，要 \(batchSize) 个")
        logger("")
        subscription.request(.max(batchSize))
    }

    func receive(_ input: Int) -> Subscribers.Demand {
        receivedInBatch += 1
        totalReceived += 1
        logger("📥 收到值: \(input)  (本批第 \(receivedInBatch)/\(batchSize) 个)")

        if receivedInBatch >= batchSize {
            receivedInBatch = 0
            logger("   ✅ 本批处理完毕!")
            logger("📤 返回 .max(\(batchSize)) → 请求下一批")
            logger("")
            return .max(batchSize)
        }

        return .none  // 本批还没收满，暂时不追加请求
    }

    func receive(completion: Subscribers.Completion<Never>) {
        logger("✅ 全部完成，共收到 \(totalReceived) 个值")
        logger("")
        logger("📝 总结: 每批请求 \(batchSize) 个")
        logger("   适用于: 分页加载、数据库批量写入等场景")
    }
}
