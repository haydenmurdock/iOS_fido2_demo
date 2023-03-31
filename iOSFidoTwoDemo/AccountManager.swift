//
//  AccountManager.swift
//  iOSFidoTwoDemo
//
//  Created by Hayden Murdock on 12/19/22.
//
//Abstract:
//The authentication manager object.
//*/

import AuthenticationServices
import Foundation
import os

extension NSNotification.Name {
    static let UserSignedIn = Notification.Name("UserSignedInNotification")
    static let ModalSignInSheetCanceled = Notification.Name("ModalSignInSheetCanceledNotification")
}

class AccountManager: NSObject, ASAuthorizationControllerPresentationContextProviding, ASAuthorizationControllerDelegate {
    let domain = "haydenapp.app.presidioidentity.net"
    var authenticationAnchor: ASPresentationAnchor?
    var isPerformingModalReqest = false

    func signInWith(anchor: ASPresentationAnchor, preferImmediatelyAvailableCredentials: Bool, challenge: Data) {
        self.authenticationAnchor = anchor
        let publicKeyCredentialProvider = ASAuthorizationPlatformPublicKeyCredentialProvider(relyingPartyIdentifier: domain)


        let assertionRequest = publicKeyCredentialProvider.createCredentialAssertionRequest(challenge: challenge)

        // Also allow the user to use a saved password, if they have one.
        let passwordCredentialProvider = ASAuthorizationPasswordProvider()
        let passwordRequest = passwordCredentialProvider.createRequest()

        // Pass in any mix of supported sign-in request types.
        let authController = ASAuthorizationController(authorizationRequests: [ assertionRequest, passwordRequest ] )
        authController.delegate = self
        authController.presentationContextProvider = self

        if preferImmediatelyAvailableCredentials {
            // If credentials are available, presents a modal sign-in sheet.
            // If there are no locally saved credentials, no UI appears and
            // the system passes ASAuthorizationError.Code.canceled to call
            // `AccountManager.authorizationController(controller:didCompleteWithError:)`.
            if #available(iOS 16.0, *) {
                authController.performRequests(options: .preferImmediatelyAvailableCredentials)
            } else {
                // Fallback on earlier versions
            }
        } else {
            // If credentials are available, presents a modal sign-in sheet.
            // If there are no locally saved credentials, the system presents a QR code to allow signing in with a
            // passkey from a nearby device.
            authController.performRequests()
        }

        isPerformingModalReqest = true
    }

    func beginAutoFillAssistedPasskeySignIn(anchor: ASPresentationAnchor, challenge: Data) {
        self.authenticationAnchor = anchor

        let publicKeyCredentialProvider = ASAuthorizationPlatformPublicKeyCredentialProvider(relyingPartyIdentifier: domain)

        // Fetch the challenge from the server. The challenge needs to be unique for each request.
        
        // change to make this presidioIdentity's challenge

        let assertionRequest = publicKeyCredentialProvider.createCredentialAssertionRequest(challenge: challenge)

        // AutoFill-assisted requests only support ASAuthorizationPlatformPublicKeyCredentialAssertionRequest.
        let authController = ASAuthorizationController(authorizationRequests: [ assertionRequest ] )
        authController.delegate = self
        authController.presentationContextProvider = self
        authController.performAutoFillAssistedRequests()
    }
    
    func signUpWith(userName: String, anchor: ASPresentationAnchor, challenge: Data) {
        print("signup hit")
        self.authenticationAnchor = anchor
        let publicKeyCredentialProvider = ASAuthorizationPlatformPublicKeyCredentialProvider(relyingPartyIdentifier: domain)

        // Fetch the challenge from the server. The challenge needs to be unique for each request.
        // The userID is the identifier for the user's account.
        
        let userID = Data(UUID().uuidString.utf8)
        print("challenge string passed to registration request: \(String(data: challenge, encoding: .utf8))")
        let registrationRequest = publicKeyCredentialProvider.createCredentialRegistrationRequest(challenge: challenge,name: userName, userID: userID)

        // Use only ASAuthorizationPlatformPublicKeyCredentialRegistrationRequests or
        // ASAuthorizationSecurityKeyPublicKeyCredentialRegistrationRequests here.
        let authController = ASAuthorizationController(authorizationRequests: [ registrationRequest ] )
        authController.delegate = self
        authController.presentationContextProvider = self
        authController.performRequests()
        isPerformingModalReqest = true
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        switch authorization.credential {
        case let credentialRegistration as ASAuthorizationPlatformPublicKeyCredentialRegistration:
           print("A new passkey was registered: \(credentialRegistration)")
            // Verify the attestationObject and clientDataJSON with your service.
            // The attestationObject contains the user's new public key to store and use for subsequent sign-ins.
            PresidioIdentityModelController().registerUserNameReponse(credentialRegistration: credentialRegistration) { data in
                if let data = data {
                    print("data received. \(data)")
                }
            }

            // After the server verifies the registration and creates the user account, sign in the user with the new account.
            didFinishSignIn()
        case let credentialAssertion as ASAuthorizationPlatformPublicKeyCredentialAssertion:
            print("A passkey was used to sign in: \(credentialAssertion)")
            // Verify the below signature and clientDataJSON with your service for the given userID.
//             let signature = credentialAssertion.signature
//             let clientDataJSON = credentialAssertion.rawClientDataJSON
//             let userID = credentialAssertion.userID

            // After the server verifies the assertion, sign in the user.
            didFinishSignIn()
        case let passwordCredential as ASPasswordCredential:
            print("A password was provided: \(passwordCredential)")
            // Verify the userName and password with your service.
            // let userName = passwordCredential.user
            // let password = passwordCredential.password

            // After the server verifies the userName and password, sign in the user.
            didFinishSignIn()
        default:
            fatalError("Received unknown authorization type.")
        }

        isPerformingModalReqest = false
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        let logger = Logger()
        guard let authorizationError = error as? ASAuthorizationError else {
            isPerformingModalReqest = false
            logger.error("Unexpected authorization error: \(error.localizedDescription)")
            return
        }

        if authorizationError.code == .canceled {
            // Either the system doesn't find any credentials and the request ends silently, or the user cancels the request.
            // This is a good time to show a traditional login form, or ask the user to create an account.

            if isPerformingModalReqest {
                didCancelModalSheet()
            }
        } else {
            // Another ASAuthorization error.
            // Note: The userInfo dictionary contains useful information.
            logger.error("Error: \((error as NSError).userInfo)")
        }

        isPerformingModalReqest = false
    }

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return authenticationAnchor!
    }

    func didFinishSignIn() {
        NotificationCenter.default.post(name: .UserSignedIn, object: nil)
    }

    func didCancelModalSheet() {
        NotificationCenter.default.post(name: .ModalSignInSheetCanceled, object: nil)
    }
}

