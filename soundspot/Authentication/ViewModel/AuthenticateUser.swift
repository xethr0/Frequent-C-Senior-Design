//
//  AuthenticateUser.swift
//  soundspot
//
//  Created by Yassine Regragui on 11/7/21.
//

import Foundation


final class AuthenticateUser : ObservableObject{
    
    private var userRepository = UserAuthRepository()
    
    private var model : AuthenticationModel = AuthenticationModel()
    let userIdString = "Enter username or email"
    let usernameString = "Enter your username"
    let emailString = "Enter your email"
    let passwordString = "Enter your password"
    let confirmPasswordString = "Confirm password"
    var alertTitleString = "Oops, something went wrong"
    var alertMessageString = "Unable to process request."
    var alertActionString = "OK"
    
    @Published var authenticated = false
    @Published var loginModel = AuthenticationModel.LoginModel()
    @Published var signupModel = AuthenticationModel.SignUpModel()
    // used to show either login or sign up forms
    @Published var formType = AuthenticationModel.FormType.login
    @Published var showAlert = false
    
    
    
    // MARK: - Intent(s)
    func updateFormType(type : AuthenticationModel.FormType){
        formType = type
    }
    
    
    func createUserAccountAsync(){
        attemptSignupAsync(user: signupModel.AsSignUpDTO()){ result in
            DispatchQueue.main.async {
                [self] in
                switch result{
                case .success(let allowUser):
                    TabBarVisibility.getInstance().show = true
                    authenticated = allowUser
                case .failure(let error):
                    switch error{
                    case UserRepositoryError.UnableToCreateUser(let e):
                        if(e != nil){
                            let responseError = e! as AuthResult.Errors
                            if(responseError.email != nil){
                                signupModel.emailError = (responseError.email)!
                            }
                            if(responseError.username != nil){
                                signupModel.usernameError = (responseError.username)!
                            }
                            if(responseError.password != nil){
                                signupModel.passwordError = (responseError.password)!
                            }
                            if(responseError.confirmPassword != nil){
                                signupModel.confirmPasswordError = (responseError.confirmPassword)!
                            }
                        }
                    default:
                        showAlert = true
                    }
                }
                    
            }
        }
    }
    
    private func attemptSignupAsync(user : UserSignUpDTO, completion: @escaping (Swift.Result<Bool, Error>) -> Void){
        DispatchQueue.global(qos: .userInitiated).async{
            [self] in
            do{
                let allowUser = try userRepository.createUser(user)
                completion(.success(allowUser))
            }catch{
                completion(.failure(error))
            }
        }
    }
    
    func logInUserAsync(){
        attemptLoginAsync(user: loginModel.AsLoginDTO()){ result in
            DispatchQueue.main.async {
                [self] in
                switch result{
                case .success(let allowUser):
                    TabBarVisibility.getInstance().show = true
                    authenticated = allowUser
                case .failure(let error):
                    switch error{
                    case UserValidationError.invalidEmail(let reason):
                        loginModel.usernameError = reason
                    case UserValidationError.invalidPassword(let reason):
                        loginModel.passwordError = reason
                    case UserRepositoryError.UnableToAuthUser(let reason):
                        if(reason == nil){
                            print("Reason is null")
                        }
                        if(reason?.email != nil){
                            print(reason?.email ?? "email error")
                            loginModel.usernameError = reason?.email ?? "username error"
                        }
                        if(reason?.password != nil){
                            print(reason?.password ?? "password error")
                            loginModel.passwordError = reason?.password ?? "password error"
                        }
                    default:
                        showAlert = true
                    }
                }
            }
        }
    }
    
    private func attemptLoginAsync(user : UserLoginDTO, completion: @escaping (Swift.Result<Bool, Error>) -> Void){
        DispatchQueue.global(qos: .userInitiated).async{
            [self] in
            do{
                let allowUser = try userRepository.logInUser(user)
                completion(.success(allowUser))
            }catch{
                completion(.failure(error))
            }
        }
    }
    
    func clearLoginUsernameError(){loginModel.usernameError = ""}
    func clearLoginPasswordError(){loginModel.passwordError = ""}
    
    func clearSignUpUsernameError(){signupModel.usernameError = ""}
    func clearSignUpEmailError(){signupModel.emailError = ""}
    func clearSignUpPasswordError(){signupModel.passwordError = ""}
    func clearSignUpConfirmPasswordError(){ signupModel.confirmPasswordError = ""}
}

