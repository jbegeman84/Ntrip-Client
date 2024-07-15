//
//  MountPointViewController.swift
//  Ntrip-Client
//
//  Created by Justin Begeman on 7/15/24.
//

import UIKit

protocol MountPointSelectionDelegate: AnyObject {
    func didSelectMountPoint(_ mountPoint: String)
}

class MountPointViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    var casterAddress: String!
    var port: Int!
    var username: String!
    var password: String!
    weak var delegate: MountPointSelectionDelegate?
    
    var mountPointsTableView: UITableView!
    var mountPoints: [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        fetchMountPoints()
    }
    
    func setupUI() {
        // Initialize and configure table view
        mountPointsTableView = UITableView()
        mountPointsTableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        mountPointsTableView.dataSource = self
        mountPointsTableView.delegate = self
        
        // Add components to the view and set constraints (using Auto Layout)
        let stackView = UIStackView(arrangedSubviews: [mountPointsTableView])
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
    
    func fetchMountPoints() {
        let client = NtripHandler(casterAddress: casterAddress, port: port, username: username, password: password, mountPoint: "", sendNMEA: false)
        
        client.fetchMountPoints { [weak self] success, mountPoints, message in
            DispatchQueue.main.async {
                if success, let mountPoints = mountPoints {
                    self?.mountPoints = mountPoints
                    self?.mountPointsTableView.reloadData()
                } else {
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
    
    // UITableViewDataSource methods
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return mountPoints.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = mountPoints[indexPath.row]
        return cell
    }
    
    // UITableViewDelegate methods
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedMountPoint = mountPoints[indexPath.row]
        delegate?.didSelectMountPoint(selectedMountPoint)
        dismiss(animated: true, completion: nil)
    }
}
