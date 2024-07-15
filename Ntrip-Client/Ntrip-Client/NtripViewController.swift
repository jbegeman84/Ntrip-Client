//
//  ViewController.swift
//  Ntrip-Client
//
//  Created by Justin Begeman on 7/14/24.
//

import UIKit

class NtripViewController: UIViewController, MountPointSelectionDelegate {
    
    var casterAddressTextField: UITextField!
    var portTextField: UITextField!
    var usernameTextField: UITextField!
    var passwordTextField: UITextField!
    var mountPointTextField: UITextField!
    var sendNMEASwitch: UISwitch!
    var connectionStatusLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
    }
    
    func setupUI() {
        // Initialize and configure text fields, labels, and switch
        casterAddressTextField = UITextField()
        casterAddressTextField.placeholder = "Caster Address"
        casterAddressTextField.borderStyle = .roundedRect
        casterAddressTextField.text = "127.0.0.1"
        
        portTextField = UITextField()
        portTextField.placeholder = "Port"
        portTextField.borderStyle = .roundedRect
        portTextField.keyboardType = .numberPad
        portTextField.text = "2101"
        
        usernameTextField = UITextField()
        usernameTextField.placeholder = "Username"
        usernameTextField.borderStyle = .roundedRect
        usernameTextField.text = "username"
        
        passwordTextField = UITextField()
        passwordTextField.placeholder = "Password"
        passwordTextField.borderStyle = .roundedRect
        passwordTextField.isSecureTextEntry = true
        passwordTextField.text = "password"
        
        mountPointTextField = UITextField()
        mountPointTextField.placeholder = "Mount Point"
        mountPointTextField.borderStyle = .roundedRect
        mountPointTextField.text = "PBCH"
        
        sendNMEASwitch = UISwitch()
        
        connectionStatusLabel = UILabel()
        connectionStatusLabel.text = "Disconnected"
        connectionStatusLabel.textColor = .red
        
        let getMountPointsButton = UIButton(type: .system)
        getMountPointsButton.setTitle("Get Mount Points", for: .normal)
        getMountPointsButton.addTarget(self, action: #selector(getMountPointsButtonTapped), for: .touchUpInside)
        
        let connectButton = UIButton(type: .system)
        connectButton.setTitle("Connect", for: .normal)
        connectButton.addTarget(self, action: #selector(connectButtonTapped), for: .touchUpInside)
        
        // Add components to the view and set constraints (using Auto Layout)
        let stackView = UIStackView(arrangedSubviews: [casterAddressTextField, portTextField, usernameTextField, passwordTextField, mountPointTextField, sendNMEASwitch, connectionStatusLabel, getMountPointsButton, connectButton])
        stackView.axis = .vertical
        stackView.spacing = 8
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])
    }
    
    @objc func getMountPointsButtonTapped() {
        guard let casterAddress = casterAddressTextField.text,
              let portText = portTextField.text, let port = Int(portText),
              let username = usernameTextField.text,
              let password = passwordTextField.text else {
            showError(message: "Please fill in all fields")
            return
        }
        
        let mountPointVC = MountPointViewController()
        mountPointVC.casterAddress = casterAddress
        mountPointVC.port = port
        mountPointVC.username = username
        mountPointVC.password = password
        mountPointVC.delegate = self
        
        present(mountPointVC, animated: true, completion: nil)
    }
    
    @objc func connectButtonTapped() {
        guard let casterAddress = casterAddressTextField.text,
              let portText = portTextField.text, let port = Int(portText),
              let username = usernameTextField.text,
              let password = passwordTextField.text,
              let mountPoint = mountPointTextField.text else {
            showError(message: "Please fill in all fields")
            return
        }
        
        print("Passed Guard Clause On Connect")
        let sendNMEA = sendNMEASwitch.isOn
        let client = NtripHandler(casterAddress: casterAddress, port: port, username: username, password: password, mountPoint: mountPoint, sendNMEA: sendNMEA)
        
        client.connect { [weak self] success, message in
            DispatchQueue.main.async {
                if success {
                    print("Success")
                    self?.connectionStatusLabel.text = "Connected"
                    self?.connectionStatusLabel.textColor = .green
                } else {
                    print("Error")
                    self?.showError(message: message)
                }
            }
        }
    }
    
    func showError(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    // MountPointSelectionDelegate method
    func didSelectMountPoint(_ mountPoint: String) {
        mountPointTextField.text = mountPoint
    }
}
