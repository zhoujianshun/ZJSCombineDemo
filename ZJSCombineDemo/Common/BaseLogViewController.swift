import UIKit
import Combine

/// 各章节 Demo 页面的基类，提供日志输出区域和按钮控制区域
class BaseLogViewController: UIViewController {

    let logTextView: UITextView = {
        let tv = UITextView()
        tv.isEditable = false
        tv.font = .monospacedSystemFont(ofSize: 13, weight: .regular)
        tv.backgroundColor = .secondarySystemBackground
        tv.textContainerInset = UIEdgeInsets(top: 12, left: 8, bottom: 12, right: 8)
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.layer.cornerRadius = 8
        tv.clipsToBounds = true
        return tv
    }()

    let controlStackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = 8
        sv.alignment = .fill
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    var cancellables = Set<AnyCancellable>()

    private let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "HH:mm:ss.SSS"
        return df
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "清空", style: .plain, target: self, action: #selector(clearLog)
        )
        setupLayout()
    }

    private func setupLayout() {
        let controlScroll = UIScrollView()
        controlScroll.translatesAutoresizingMaskIntoConstraints = false
        controlScroll.showsVerticalScrollIndicator = false
        controlScroll.addSubview(controlStackView)

        view.addSubview(controlScroll)
        view.addSubview(logTextView)

        let safeArea = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            controlScroll.topAnchor.constraint(equalTo: safeArea.topAnchor),
            controlScroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            controlScroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            controlScroll.heightAnchor.constraint(lessThanOrEqualTo: view.heightAnchor, multiplier: 0.4),

            controlStackView.topAnchor.constraint(equalTo: controlScroll.topAnchor, constant: 12),
            controlStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            controlStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            controlStackView.bottomAnchor.constraint(equalTo: controlScroll.bottomAnchor, constant: -12),

            logTextView.topAnchor.constraint(equalTo: controlScroll.bottomAnchor, constant: 4),
            logTextView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            logTextView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            logTextView.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor, constant: -12),
        ])
    }

    func log(_ message: String) {
        let time = dateFormatter.string(from: Date())
        logTextView.text += "[\(time)] \(message)\n"
        let end = NSRange(location: (logTextView.text as NSString).length - 1, length: 1)
        logTextView.scrollRangeToVisible(end)
    }

    @objc func clearLog() {
        logTextView.text = ""
    }

    func addButton(title: String, action: @escaping () -> Void) {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.heightAnchor.constraint(equalToConstant: 40).isActive = true
        button.addAction(UIAction { _ in action() }, for: .touchUpInside)
        controlStackView.addArrangedSubview(button)
    }

    func addSectionHeader(_ text: String) {
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 13, weight: .bold)
        label.textColor = .secondaryLabel
        controlStackView.addArrangedSubview(label)
    }
}
