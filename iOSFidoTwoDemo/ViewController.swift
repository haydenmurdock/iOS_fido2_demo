//
//  ViewController.swift
//  iOSFidoTwoDemo
//
//  Created by Hayden Murdock on 8/22/22.
//

import UIKit
import SingularKey


class ViewController: UIViewController {
    // Add Add NSFaceIDUsageDescription (Privacy — Face ID Usage Description)
    
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var blueBackgroundUIView: UIView!
    let activityIndicator = UIActivityIndicatorView()
    let blurView = UIView()
    @IBOutlet weak var signInButton: UIButton!
    @IBOutlet weak var signUpbutton: UIButton!
    @IBOutlet weak var noaccountLabel: UILabel!
    @IBOutlet weak var headingLabel: UILabel!
    private var signInObserver: NSObjectProtocol?
    private var signInErrorObserver: NSObjectProtocol?
    var challenge: Data?
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        roundView()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .light
        roundView()
        
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        signInObserver = NotificationCenter.default.addObserver(forName: .UserSignedIn, object: nil, queue: nil) {_ in
            self.didFinishSignIn()
        }
        
        signInErrorObserver = NotificationCenter.default.addObserver(forName: .ModalSignInSheetCanceled, object: nil, queue: nil) { _ in
            guard let username = self.usernameTextField.text else {
                self.removeBlurView()
                return
            }
            self.showAlertController()
           // self.createAccount(username: username)
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        if let signInObserver = signInObserver {
            NotificationCenter.default.removeObserver(signInObserver)
        }

        if let signInErrorObserver = signInErrorObserver {
            NotificationCenter.default.removeObserver(signInErrorObserver)
        }
        showSignInUI()
        super.viewDidDisappear(animated)
    }
    
    @IBAction func submitBtnTouched(_ sender: Any) {
        self.view.endEditing(true)
        guard let username = usernameTextField.text, username.count > 0 else {return}
        addBlurView()
        createAccount(username: username)
    }
    
    @IBAction func signUpbuttonPressed(_ sender: Any) {
        showSignUpUI()
    }
    
    func didFinishSignIn() {
        removeBlurView()
        toBankHome()
    }
    
    func roundView() {
        blueBackgroundUIView.layer.cornerRadius = 20
    }
    @objc func toBankHome() {
        performSegue(withIdentifier: "toBankAccount", sender: self)
    }
    private func addBlurView(){
        blurView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(blurView)
        blurView.frame = self.view.frame
        let blurEffect = UIBlurEffect(style: UIBlurEffect.Style.dark)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = view.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        blurView.addSubview(blurEffectView)
        
        
        activityIndicator.color = .white
        self.view.addSubview(activityIndicator)
        activityIndicator.center = blurView.center
        activityIndicator.startAnimating()
        
        
    }
    
    private func removeBlurView() {
        blurView.removeFromSuperview()
        activityIndicator.removeFromSuperview()
    }
    
    func createAccount(username: String){
        if username.count < 0 {
            print("no username entered")
            return
        }

        guard let window = self.view.window else { fatalError("The view was not in the app's view hierarchy!") }
        (UIApplication.shared.delegate as? AppDelegate)?.accountManager.signUpWith(userName: username, anchor: window)
    }
    func showAlertController() {
        let dialogMessage = UIAlertController(title: "Canceled", message: "Passkey sign in was canceled", preferredStyle: .alert)
        let cancelAccountAction = UIAlertAction(title: "Back to Sign In", style: .default, handler:{ (action) -> Void in
            self.removeBlurView()
         })
        dialogMessage.addAction(cancelAccountAction)
        // Present alert to user
        self.present(dialogMessage, animated: true, completion: nil)
    }
    @IBAction func signInButtonPressed(_ sender: Any) {
        addBlurView()
        guard let window = self.view.window else { fatalError("The view was not in the app's view hierarchy!") }
                PresidioIdentityModelController.shared.sendUserName(userName: "iOSpasskeyDemo", displayName: "iOSpasskeyDemo") { response in
               if let response = response {
                   DispatchQueue.main.async {
                     (UIApplication.shared.delegate as? AppDelegate)?.accountManager.signInWith(anchor: window, preferImmediatelyAvailableCredentials: true, challenge: (response))
                   }
               }
           }
    }
    
    func showSignUpUI() {
        usernameTextField.isHidden = false
        usernameTextField.isUserInteractionEnabled = true
        signInButton.isHidden = true
        signInButton.isUserInteractionEnabled = false
        
        noaccountLabel.isHidden = true
        signUpbutton.isHidden = true
        headingLabel.text = "Sign Up"
        usernameTextField.becomeFirstResponder()
        view.updateConstraints()
    }
    func showSignInUI() {
        usernameTextField.isHidden = true
        usernameTextField.isUserInteractionEnabled = false
        signInButton.isHidden = false
        signInButton.isUserInteractionEnabled = true
        
        noaccountLabel.isHidden = false
        signUpbutton.isHidden = false
        headingLabel.text = "Welcome Back"
        view.updateConstraints()
    }
}

