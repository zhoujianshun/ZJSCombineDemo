import UIKit
import Combine

class LoginViewController: UIViewController {

    private let viewModel = LoginViewModel()
    private var cancellables = Set<AnyCancellable>()

    // MARK: - UI Elements

    private let scrollView = UIScrollView()
    private let stackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = 12
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    private let usernameField = LoginViewController.makeTextField(placeholder: "用户名 (至少3个字符)")
    private let usernameStatus = LoginViewController.makeStatusLabel()

    private let passwordField = LoginViewController.makeTextField(placeholder: "密码 (至少6个字符)", isSecure: true)
    private let passwordStatus = LoginViewController.makeStatusLabel()

    private let confirmField = LoginViewController.makeTextField(placeholder: "确认密码", isSecure: true)
    private let confirmStatus = LoginViewController.makeStatusLabel()

    private let loginButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("注 册", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 17, weight: .bold)
        btn.backgroundColor = .systemBlue
        btn.setTitleColor(.white, for: .normal)
        btn.setTitleColor(.lightGray, for: .disabled)
        btn.layer.cornerRadius = 10
        btn.heightAnchor.constraint(equalToConstant: 48).isActive = true
        btn.isEnabled = false
        return btn
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupLayout()
        setupBindings()
    }

    // MARK: - Layout

    private func setupLayout() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.addSubview(stackView)

        let safeArea = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: safeArea.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor),

            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 24),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -24),
        ])

        let header = UILabel()
        header.text = "Combine + MVVM 表单验证"
        header.font = .systemFont(ofSize: 20, weight: .bold)
        header.textAlignment = .center

        [header,
         usernameField, usernameStatus,
         passwordField, passwordStatus,
         confirmField, confirmStatus,
         loginButton
        ].forEach { stackView.addArrangedSubview($0) }

        stackView.setCustomSpacing(24, after: header)
        stackView.setCustomSpacing(24, after: confirmStatus)
    }

    // MARK: - Combine Bindings

    private func setupBindings() {
        // TextField → ViewModel
        bindTextField(usernameField, to: \.username)
        bindTextField(passwordField, to: \.password)
        bindTextField(confirmField,  to: \.confirmPassword)

        // ViewModel → Validation UI
        viewModel.isUsernameValid
            .receive(on: DispatchQueue.main)
            .sink { [weak self] valid in
                self?.usernameStatus.text = valid ? "✅ 用户名有效" : "❌ 至少3个字符"
                self?.usernameStatus.textColor = valid ? .systemGreen : .systemRed
            }
            .store(in: &cancellables)

        viewModel.isPasswordValid
            .receive(on: DispatchQueue.main)
            .sink { [weak self] valid in
                self?.passwordStatus.text = valid ? "✅ 密码有效" : "❌ 至少6个字符"
                self?.passwordStatus.textColor = valid ? .systemGreen : .systemRed
            }
            .store(in: &cancellables)

        viewModel.isPasswordMatch
            .receive(on: DispatchQueue.main)
            .sink { [weak self] match in
                self?.confirmStatus.text = match ? "✅ 密码一致" : "❌ 密码不一致"
                self?.confirmStatus.textColor = match ? .systemGreen : .systemRed
            }
            .store(in: &cancellables)

        // Form validity → Button
        viewModel.isFormValid
            .receive(on: DispatchQueue.main)
            .sink { [weak self] valid in
                self?.loginButton.isEnabled = valid
                self?.loginButton.backgroundColor = valid ? .systemBlue : .systemGray4
            }
            .store(in: &cancellables)

        // Login action
        loginButton.addAction(UIAction { [weak self] _ in
            let alert = UIAlertController(
                title: "注册成功",
                message: "用户: \(self?.viewModel.username ?? "")",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "好的", style: .default))
            self?.present(alert, animated: true)
        }, for: .touchUpInside)
    }

    private func bindTextField(_ field: UITextField, to keyPath: ReferenceWritableKeyPath<LoginViewModel, String>) {
        NotificationCenter.default
            .publisher(for: UITextField.textDidChangeNotification, object: field)
            .compactMap { ($0.object as? UITextField)?.text }
            .assign(to: keyPath, on: viewModel)
            .store(in: &cancellables)
    }

    // MARK: - Factory

    private static func makeTextField(placeholder: String, isSecure: Bool = false) -> UITextField {
        let tf = UITextField()
        tf.placeholder = placeholder
        tf.borderStyle = .roundedRect
        tf.isSecureTextEntry = isSecure
        tf.autocapitalizationType = .none
        tf.autocorrectionType = .no
        tf.heightAnchor.constraint(equalToConstant: 44).isActive = true
        return tf
    }

    private static func makeStatusLabel() -> UILabel {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13)
        label.textColor = .secondaryLabel
        label.text = " "
        return label
    }
}
