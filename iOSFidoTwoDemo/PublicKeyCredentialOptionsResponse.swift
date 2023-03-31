//
//  PublicKeyCredentialOptionsResponse.swift
//  iOSFidoTwoDemo
//
//  Created by Hayden Murdock on 8/22/22.
//
// {
//"status": "ok",
//"errorMessage": "",
//"rp": {
//    "id": "https://develop.presidioidentity.net",
//    "name": "Presidio Identity"
//},
//"user": {
//    "id": "NjMwNTFlNzc0Y2E5MjMwMDI2ZWY0ZDdm",
//    "name": "nehav",
//    "displayName": "neha8484"
//},
//"challenge": "IW54fXBD18gIR25qhS1cqTvaMNsOCCUk19p3If4lA",
//"pubKeyCredParams": [
//    {
//        "type": "public-key",
//        "alg": -7
//    },
//    {
//        "type": "public-key",
//        "alg": -257
//    }
//],
//"timeout": 1000000,
//"excludeCredentials": [
//    {
//        "id": "noExcludeCredentials",
//        "type": "public-key"
//    }
//],
//"authenticatorSelection": "{ requireResidentKey: false, userVerification: 'preferred' }",
//"attestation": "none"

import Foundation

struct PublicKeyCreationsResponse: Codable {
    var status: String?
    var errorMessage: String?
    var rp: Rp?
    var user: User?
    var challenge: String?
    var pubKeyCredParams: [PublicKeyCredentials]?
    var timeout: Int?
    var excludeCredentials: [ExcludeCredentials]?
    var authenticatorSelection: AuthenticatorSelection?
    var attestation: String?
}

struct Rp: Codable{
    var id: String?
    var name: String?
}

struct User: Codable {
    var id: String?
    var name: String?
    var displayName: String?
}

struct PublicKeyCredentials: Codable{
    var type: String?
    var alg: Int?
}
struct ExcludeCredentials: Codable {
    var id: String?
    var type: String?
}

struct AuthenticatorSelection: Codable {
    var requiresResidentKey: String?
    var userVerificiation: String?
    var authenticatorAttachement: String?
}

struct UserNamePostRequest: Codable {
        var username : String?
        var displayName: String?
        var attestation: String?
        var authenticatorSelection: Data?
}


