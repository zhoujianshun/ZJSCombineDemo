import UIKit
import Combine

// MARK: - Models

struct Post: Codable {
    let userId: Int
    let id: Int
    let title: String
    let body: String
}

struct PostAuthor: Codable {
    let id: Int
    let name: String
    let email: String
    let phone: String
}

// MARK: - ViewController

class NetworkingViewController: BaseLogViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        addButton(title: "GET 请求 (原始数据)")    { [weak self] in self?.demoGet() }
        addButton(title: "JSON 解析 (decode)")     { [weak self] in self?.demoJSONDecode() }
        addButton(title: "错误处理 (retry + catch)") { [weak self] in self?.demoErrorHandling() }
        addButton(title: "链式请求 (flatMap)")       { [weak self] in self?.demoChainedRequests() }
    }

    // MARK: - GET 请求

    private func demoGet() {
        log("--- GET 请求 ---")
        guard let url = URL(string: "https://jsonplaceholder.typicode.com/posts/1") else { return }

        URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.log("❌ 失败: \(error.localizedDescription)")
                    }
                },
                receiveValue: { [weak self] data in
                    self?.log("✅ 收到 \(data.count) bytes")
                    if let text = String(data: data, encoding: .utf8)?.prefix(150) {
                        self?.log("内容: \(text)...")
                    }
                }
            )
            .store(in: &cancellables)
    }

    // MARK: - JSON 解析

    private func demoJSONDecode() {
        log("--- JSON 解析: dataTaskPublisher + decode ---")
        guard let url = URL(string: "https://jsonplaceholder.typicode.com/posts/1") else { return }

        URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: Post.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.log("❌ \(error)")
                    }
                },
                receiveValue: { [weak self] post in
                    self?.log("✅ Post #\(post.id)")
                    self?.log("   标题: \(post.title)")
                    self?.log("   作者ID: \(post.userId)")
                }
            )
            .store(in: &cancellables)
    }

    // MARK: - 错误处理

    private func demoErrorHandling() {
        log("--- 错误处理: retry + catch ---")
        log("访问无效 URL，重试2次后使用默认值")
        guard let url = URL(string: "https://invalid-url-that-does-not-exist.example/api") else { return }

        URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: Post.self, decoder: JSONDecoder())
            .retry(2)
            .catch { [weak self] error -> Just<Post> in
                self?.log("⚠️ 所有重试失败: \(error.localizedDescription)")
                return Just(Post(userId: 0, id: 0, title: "默认标题", body: "网络不可用"))
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] post in
                self?.log("最终结果: \(post.title) - \(post.body)")
            }
            .store(in: &cancellables)
    }

    // MARK: - 链式请求: 先获取 Post，再获取作者信息

    private func demoChainedRequests() {
        log("--- 链式请求: Post → Author ---")
        log("第1步: 获取 Post...")
        guard let url = URL(string: "https://jsonplaceholder.typicode.com/posts/1") else { return }

        URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: Post.self, decoder: JSONDecoder())
            .flatMap { [weak self] post -> AnyPublisher<PostAuthor, Error> in
                self?.log("Post 作者 userId = \(post.userId)")
                self?.log("第2步: 获取用户信息...")
                let userURL = URL(string: "https://jsonplaceholder.typicode.com/users/\(post.userId)")!
                return URLSession.shared.dataTaskPublisher(for: userURL)
                    .map(\.data)
                    .decode(type: PostAuthor.self, decoder: JSONDecoder())
                    .eraseToAnyPublisher()
            }
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.log("❌ 链式请求失败: \(error)")
                    }
                },
                receiveValue: { [weak self] author in
                    self?.log("✅ 作者: \(author.name)")
                    self?.log("   邮箱: \(author.email)")
                    self?.log("   电话: \(author.phone)")
                }
            )
            .store(in: &cancellables)
    }
}
