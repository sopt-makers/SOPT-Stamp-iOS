//
//  SignUpUseCase.swift
//  Domain
//
//  Created by sejin on 2022/11/28.
//  Copyright © 2022 SOPT-Stamp-iOS. All rights reserved.
//

import Foundation
import Combine

import Core

public protocol SignUpUseCase {
    func resetNicknameValidation()
    func checkNickname(nickname: String)
    func resetEmailValidation()
    func checkEmail(email: String)
    func checkPassword(password: String)
    func checkAccordPassword(firstPassword: String, secondPassword: String)
    func signUp(signUpRequest: SignUpModel)
    
    var isNicknameValid: CurrentValueSubject<(Bool, String), Error> { get set }
    var isEmailFormValid: CurrentValueSubject<Bool, Error> { get set }
    var isDuplicateEmail: CurrentValueSubject<Bool, Error> { get set }
    var isPasswordFormValid: CurrentValueSubject<Bool, Error> { get set }
    var isAccordPassword: CurrentValueSubject<Bool, Error> { get set }
    var isValidForm: CurrentValueSubject<Bool, Error> { get set }
    var signUpSuccess: CurrentValueSubject<Bool, Error> { get set }
}

public class DefaultSignUpUseCase {
    
    private let repository: SignUpRepositoryInterface
    private var cancelBag = CancelBag()
    
    public var isNicknameValid = CurrentValueSubject<(Bool, String), Error>((false, ""))
    public var isEmailFormValid = CurrentValueSubject<Bool, Error>(false)
    public var isDuplicateEmail = CurrentValueSubject<Bool, Error>(false)
    public var isPasswordFormValid = CurrentValueSubject<Bool, Error>(false)
    public var isAccordPassword = CurrentValueSubject<Bool, Error>(false)
    public var isValidForm = CurrentValueSubject<Bool, Error>(false)
    public var signUpSuccess = CurrentValueSubject<Bool, Error>(false)
    
    public init(repository: SignUpRepositoryInterface) {
        self.repository = repository
        self.bindFormValid()
    }
}

extension DefaultSignUpUseCase: SignUpUseCase {
    public func resetNicknameValidation() {
        self.isValidForm.send(false)
    }
    
    public func resetEmailValidation() {
        self.isValidForm.send(false)
    }
    
    public func checkNickname(nickname: String) {
        let nicknameRegEx = "[가-힣ㄱ-ㅣA-Za-z\\s]{1,10}"
        let pred = NSPredicate(format: "SELF MATCHES %@", nicknameRegEx)
        let isValidForRegex = pred.evaluate(with: nickname)
        let isEmptyNickname = nickname.replacingOccurrences(of: " ", with: "").count == 0
        guard isValidForRegex && !isEmptyNickname else {
            self.isNicknameValid.send((false, I18N.SignUp.nicknameTextFieldPlaceholder))
            return
        }
        
        repository.getNicknameAvailable(nickname: nickname)
            .sink { event in
                print("SignUpUseCase nickname: \(event)")
            } receiveValue: { isValid in
                if isValid {
                    self.isNicknameValid.send((true, I18N.SignUp.validNickname))
                } else {
                    self.isNicknameValid.send((false, I18N.SignUp.duplicatedNickname))
                }
            }.store(in: cancelBag)
    }
    
    public func checkEmail(email: String) {
        let isValid = checkEmailForm(email: email)
        self.isEmailFormValid.send(isValid)

        guard isValid else { return }

        repository.getEmailAvailable(email: email)
            .sink { event in
                print("SignUpUseCase email: \(event)")
            } receiveValue: { isValid in
                self.isDuplicateEmail.send(!isValid)
            }.store(in: cancelBag)
    }
    
    public func checkPassword(password: String) {
        checkPasswordForm(password: password)
    }
    
    public func checkAccordPassword(firstPassword: String, secondPassword: String) {
        checkAccordPasswordForm(firstPassword: firstPassword, secondPassword: secondPassword)
    }
    
    public func signUp(signUpRequest: SignUpModel) {
        repository.postSignUp(signUpRequest: signUpRequest)
            .sink { event in
                print("SignUpUseCase signUp: \(event)")
            } receiveValue: { isValid in
                self.signUpSuccess.send(isValid)
            }.store(in: cancelBag)
    }
}

// MARK: - Methods

extension DefaultSignUpUseCase {
    func bindFormValid() {
        let nickNameAndEmailValid = isNicknameValid
            .map { $0.0 }
            .combineLatest(isEmailFormValid, isDuplicateEmail)
        
        let passwordValid = isPasswordFormValid
            .combineLatest(isAccordPassword)
        
        nickNameAndEmailValid.combineLatest(passwordValid)
        .sink { event in
            print("SignUpUseCase signUp: \(event)")
        } receiveValue: { validList in
            let isNickNamdAndEmailValid = (validList.0.0 && validList.0.1 && !validList.0.2)
            let isPasswordValid = (validList.1.0 && validList.1.1)
            self.isValidForm.send(isNickNamdAndEmailValid && isPasswordValid)
        }.store(in: cancelBag)
    }
    
    func checkEmailForm(email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailTest = NSPredicate(format: "SELF MATCHES %@", emailRegEx)
        let isValid = emailTest.evaluate(with: email)
        return isValid
    }
    
    func checkPasswordForm(password: String) {
        let passwordRegEx = "^(?=.*[A-Za-z])(?=.*[0-9])(?=.*[!@#$%^&*()_+=-]).{8,15}" // 8자리 ~ 15자리 영어+숫자+특수문자
        let passwordTest = NSPredicate(format: "SELF MATCHES %@", passwordRegEx)
        let isValid = passwordTest.evaluate(with: password)
        isPasswordFormValid.send(isValid)
    }
    
    func checkAccordPasswordForm(firstPassword: String, secondPassword: String) {
        let isValid = (firstPassword == secondPassword)
        isAccordPassword.send(isValid)
    }
}
