//
//  DeepseekChatVC.swift
//  demo
//
//  Created by RichardX on 2026/8/12.
//

import UIKit
import SwiftUI

@objc class ChatViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let chatView = ChatView()
        let hostingController = UIHostingController(rootView: chatView)
        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        hostingController.didMove(toParent: self)
    }
}
