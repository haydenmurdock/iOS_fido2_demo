//
//  BankAccountViewController.swift
//  iOSFidoTwoDemo
//
//  Created by Hayden Murdock on 12/20/22.
//

import UIKit

class BankAccountViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    

    @IBAction func signoutBtnPressed(_ sender: Any) {
        self.dismiss(animated: true)
    }
}
