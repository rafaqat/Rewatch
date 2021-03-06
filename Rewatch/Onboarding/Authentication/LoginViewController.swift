//
//  ViewController.swift
//  Rewatch
//
//  Created by Romain Pouclet on 2015-10-15.
//  Copyright © 2015 Perfectly-Cooked. All rights reserved.
//

import UIKit
import ReactiveCocoa
import BetaSeriesKit
import SafariServices

class LoginViewController: UIViewController {
    let persistenceController: PersistenceController

    var loginView: LoginView {
        get {
            return view as! LoginView
        }
    }
    
    let authenticationController: AuthenticationController

    init(persistenceController: PersistenceController, authenticationController: AuthenticationController) {
        self.persistenceController = persistenceController
        self.authenticationController = authenticationController

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loginView.delegate = self
        
        title = "REWATCH"
        view.backgroundColor = Stylesheet.appBackgroundColor
    }
}

extension LoginViewController: LoginViewDelegate {

    func didStartAuthenticationInLoginView(loginView: LoginView) {
        let keys = NSDictionary(contentsOfFile: NSBundle.mainBundle().pathForResource("Keys", ofType: "plist")!) as! [String: String]
        let client = BetaSeriesKit.Client(key: keys["BetaseriesAPIKey"]!)
        let secret = keys["BetaseriesAPISecret"]!
        
        client
            .authenticate(secret) { [unowned self] url in
                let browser = SFSafariViewController(URL: url)
                self.presentViewController(browser, animated: true, completion: nil)
            }
            .map { BetaseriesContentController(authenticatedClient: $0) }
            .observeOn(UIScheduler())
            .startWithNext { [weak self] contentController in
                self?.dismissViewControllerAnimated(true, completion: nil)
                self?.authenticationController.contentController.value = contentController
            }
    }
}
