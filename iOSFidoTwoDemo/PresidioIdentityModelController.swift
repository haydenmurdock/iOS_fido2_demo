//
//  PresidioIdentityModelController.swift
//  iOSFidoTwoDemo
//
//  Created by Hayden Murdock on 8/22/22.
//

import Foundation


class PresidioIdentityModelController {
    static let shared = PresidioIdentityModelController()
    let baseUrl = "https://develop.presidioidentity.net/api/"
    
    func sendUserName(userName: String, displayName: String, completion: @escaping(Data?) -> Void) {
        let attestationOptionsUrlString = baseUrl + "attestation/options"
        print(attestationOptionsUrlString)
        let url = URL(string: attestationOptionsUrlString)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type") // change as per server requirements
        request.addValue("application/json", forHTTPHeaderField: "Accept")

        let authenticatorSelection = AuthenticatorSelection(requiresResidentKey: "false", userVerificiation: "preferred")

        do {
            let jsonAuthSelectionData = try JSONEncoder().encode(authenticatorSelection)
            let jsonAuthString = String(data: jsonAuthSelectionData, encoding: String.Encoding.utf8)
            
           let userNamePost = userNamePostRequest(username: userName, displayName: displayName, attestation: "none", authenticatorSelection: jsonAuthString)
            let jsonUserName = try JSONEncoder().encode(userNamePost)
            request.httpBody = jsonUserName
        print("URL Body = \(jsonUserName)")
            
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
                    completion(data)
                    if let object =  try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                        print(object)
                        var userFromDictionary: User?
                        var publicKeyCredArray: [PublicKeyCredentials] = []
                        var excludeCredentialsArray: [ExcludeCredentials] = []
                        var challenge: String?
                        var rp: Rp?
                        var timeout: Int?
                        var authenticatorSelection: AuthenticatorSelection?
                        var attestation: String?
                
                        
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
                        if let receivedChallenge = object["challange"] as? String {
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
        
//                        completion(PublicKeyCreationsResponse(status: "ok", errorMessage: "", rp: rp, user: userFromDictionary, challenge: challenge, pubKeyCredParams: publicKeyCredArray, timeout: timeout, excludeCredentials: excludeCredentialsArray, authenticatorSelection: authenticatorSelection, attestation: ""))
                        print("\(object)")
                    }
                } catch {
                    print(String(describing: error))
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
