//
//  PresidioIdentityModelController.swift
//  iOSFidoTwoDemo
//
//  Created by Hayden Murdock on 8/22/22.
//

import Foundation
import AuthenticationServices

class PresidioIdentityModelController {
    static let shared = PresidioIdentityModelController()
    let baseUrl = "https://haydenapp.app.presidioidentity.net/fido2/"
    
    func sendUserName(userName: String, displayName: String, completion: @escaping(Data?) -> Void) {
        let attestationOptionsUrlString = baseUrl + "attestation/options"

        let url = URL(string: attestationOptionsUrlString)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type") // change as per server requirements
        request.addValue("application/json", forHTTPHeaderField: "Accept")


        do {
            let jsonSelectionData: [String: Any] = ["requiresResidentKey": "false", "userVerification": "true", "authenticatorAttachement": "platform"]
            
            let userNameJson: [String: Any] = ["username": userName, "displayName": userName, "userVerification": "preferred", "attestation": "direct", "authenticatorSelection": jsonSelectionData]
            
            print("JSON being sent\(userNameJson)")
            let jsonUserName = try JSONSerialization.data(withJSONObject: userNameJson)
            request.httpBody = jsonUserName
            
        } catch {
           print(error.localizedDescription)
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print(error.localizedDescription)
                completion(nil)
            }
            if let data = data {
                do {
                    
                    if let object =  try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                        var userFromDictionary: User?
                        var publicKeyCredArray: [PublicKeyCredentials] = []
                        var excludeCredentialsArray: [ExcludeCredentials] = []
                        var challenge: String?
                        var rp: Rp?
                        var timeout: Int?
                        var authenticatorSelection: AuthenticatorSelection?
                        var attestation: String?
                        print("\(object)")
                        
                        if let status = object["status"] as? String {
                            if status != "ok"{
                                print("Error: status: \(status) for attestation/options response")
                            }
                        }
                        if let user = object["user"] as? [String: Any] {
                             userFromDictionary = self.getUser(dict: user)
                        }
                        if let publicKeyCredParams = object["pubKeyCredParams"] as? [Any]{
                            publicKeyCredArray = self.getPublicKeyCredParams(credArray: publicKeyCredParams)
                        }
                        if let excludeCredentials = object["excludeCredentials" ] as? [Any]{
                            excludeCredentialsArray = self.getExcludeCredentials(credArray: excludeCredentials)
                        }
                        if let receivedChallenge = object["challenge"] as? String {
                            challenge = receivedChallenge
                        }
                        if let receivedRp = object["rp"] as? [String: Any]{
                            rp = self.getRp(rpDict: receivedRp)
                        }
                       if let receivedAuthSelection = object["authenticatorSelection"] as? [String: Any] {
                           authenticatorSelection = self.getAuthSelection(authSelectionDict: receivedAuthSelection)
                        }
                        if let receivedTimeout = object["timeout"] as? Int {
                             timeout = receivedTimeout
                        }
                        let PKCR = PublicKeyCreationsResponse(status: "ok", errorMessage: "", rp: rp, user: userFromDictionary, challenge: challenge, pubKeyCredParams: publicKeyCredArray, timeout: timeout, excludeCredentials: excludeCredentialsArray, authenticatorSelection: authenticatorSelection, attestation: "")
                        guard let challenge = PKCR.challenge else {
                            completion(nil)
                            return
                        }
                        completion(challenge.data(using: .utf8)?.base64EncodedData())
                        
                    }
                } catch {
                    print(String(describing: error))
                }
            }
        }.resume()
    }
    
    func registerUserNameReponse(credentialRegistration: ASAuthorizationPlatformPublicKeyCredentialRegistration, completion: @escaping(Data?) -> Void) {
        
        let attestationResults = baseUrl + "attestation/result"
        
        let url = URL(string: attestationResults)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        let attestationObject = credentialRegistration.rawAttestationObject!.base64EncodedString()
        let clientDataJSON = credentialRegistration.rawClientDataJSON.base64EncodedString()
        let id = credentialRegistration.credentialID.base64EncodedString()
    
        let type = "public-key"
      
        
        do {
            let jsonSelectionData: [String: Any] = ["clientDataJSON": clientDataJSON, "attestationObject": attestationObject]
            
            let registerJson : [String: Any] = ["id": id, "type": type, "rawId": id, "response": jsonSelectionData]
            print(registerJson)
            let json = try JSONSerialization.data(withJSONObject: registerJson, options: .prettyPrinted)
            request.httpBody = json
        } catch {
            print(error.localizedDescription)
        }
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print(error.localizedDescription)
                completion(nil)
            }
            if let data = data {
                do {
                    if let object =  try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                        if let status = object["status"] as? String {
                            if status != "ok"{
                                print("Error: status: \(status) for attestation/result response")
                                if let errorMessage = object["errorMessage"] as? String {
                                    print(errorMessage)
                                }
                                completion(nil)
                            } else {
                                print("Status: ok for attestation/result reponse")
                            }
                            completion(data)
                        }
                    }
                }catch{
                    print("Issue parsing status object")
                    completion(nil)
                }
            }
        }.resume()
    }
    
    
    func getUser(dict: [String: Any])-> User? {
        var displayName: String?
        var id: String?
        var name: String?
        
        if let dName  = dict["displayName"] as? String {
            displayName = dName
        }
        if let userid  = dict["id"] as? String {
            id = userid
        }
        if let username  = dict["name"] as? String {
           name = username
        }
        return User(id: id, name: name, displayName: displayName)
    }
    
    func getRp(rpDict: [String: Any]) -> Rp? {
        var id: String?
        var name: String?
        
        if let idValue  = rpDict["id"] as? String {
           id = idValue
        }
        if let nameValue  = rpDict["name"] as? String {
           name = nameValue
        }
        return Rp(id: id, name: name)
        
    }
    
    func getAuthSelection(authSelectionDict: [String: Any]) -> AuthenticatorSelection?{
        var requiresResidentKey: String?
        var userVerification: String?
      
        if let userVerificationValue  = authSelectionDict["userVerificiation"] as? String {
           userVerification = userVerificationValue
        }
        if let requiresResidentKeyValue  = authSelectionDict["requiresResidentKey"] as? String {
          requiresResidentKey = requiresResidentKeyValue
        }
        
        return AuthenticatorSelection(requiresResidentKey: requiresResidentKey, userVerificiation: userVerification)
    }
    
    func getPublicKeyCredParams(credArray: [Any]) -> [PublicKeyCredentials]{
        var pubKeyCredArray: [PublicKeyCredentials]  = []
       
        for cred in credArray {
            let credArrayDict = cred as? [String: Any]
            guard let credArrayDict = credArrayDict else {return pubKeyCredArray}
            let alg = credArrayDict["alg"] as? Int
            let type = credArrayDict["type"] as? String
            pubKeyCredArray.append(PublicKeyCredentials(type: type, alg: alg))
        }
        return pubKeyCredArray
    }
    
    func getExcludeCredentials(credArray: [Any]) -> [ExcludeCredentials] {
        var pubKeyCredArray: [ExcludeCredentials]  = []
       
        for cred in credArray {
            let credArrayDict = cred as? [String: Any]
            guard let credArrayDict = credArrayDict else {return pubKeyCredArray}
            let id = credArrayDict["id"] as? String
            let type = credArrayDict["type"] as? String
            pubKeyCredArray.append(ExcludeCredentials(id: id, type: type))
        }
        return pubKeyCredArray
    }
}
