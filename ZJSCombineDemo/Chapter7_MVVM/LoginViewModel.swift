import Foundation
import Combine

class LoginViewModel {

    // MARK: - Input (由 View 写入)

    @Published var username = ""
    @Published var password = ""
    @Published var confirmPassword = ""

    // MARK: - Output (由 View 订阅)

    /// 用户名是否有效（>= 3 个字符）
    var isUsernameValid: AnyPublisher<Bool, Never> {
        $username
            .map { $0.count >= 3 }
            .eraseToAnyPublisher()
    }

    /// 密码是否有效（>= 6 个字符）
    var isPasswordValid: AnyPublisher<Bool, Never> {
        $password
            .map { $0.count >= 6 }
            .eraseToAnyPublisher()
    }

    /// 两次密码是否一致
    var isPasswordMatch: AnyPublisher<Bool, Never> {
        Publishers.CombineLatest($password, $confirmPassword)
            .map { password, confirm in
                !password.isEmpty && password == confirm
            }
            .eraseToAnyPublisher()
    }

    /// 整体表单是否有效
    var isFormValid: AnyPublisher<Bool, Never> {
        Publishers.CombineLatest3(
            $username.map { $0.count >= 3 },
            $password.map { $0.count >= 6 },
            Publishers.CombineLatest($password, $confirmPassword)
                .map { !$0.isEmpty && $0 == $1 }
        )
        .map { $0 && $1 && $2 }
        .eraseToAnyPublisher()
    }
}
