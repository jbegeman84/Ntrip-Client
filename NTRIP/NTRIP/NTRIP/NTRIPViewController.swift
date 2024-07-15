//
//  ViewController.swift
//  NTRIP
//
//  Created by Justin Begeman on 7/6/24.
//
import UIKit

class ViewController: UIViewController, StreamDelegate {
    var inputStream: InputStream!
    var outputStream: OutputStream!
    
    let stackView = UIStackView()
    let label = UILabel()
    let connectButton = UIButton(type: .system)
    
    var casterAddress = "127.0.0.1"
    var port = 2101
    var username = "justinbegeman"
    var password = "Spitfire84!"
    var mountPoint = "PBCH"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        style()
        layout()
        
    }
    
    @objc func connect() {
        
        var readStream: Unmanaged<CFReadStream>?
        var writeStream: Unmanaged<CFWriteStream>?
        
        CFStreamCreatePairWithSocketToHost(kCFAllocatorDefault, casterAddress as CFString, UInt32(port), &readStream, &writeStream)
        
        inputStream = readStream!.takeRetainedValue()
        outputStream = writeStream!.takeRetainedValue()
        
        
        inputStream.delegate = self
        outputStream.delegate = self
        
        inputStream.schedule(in: .current, forMode: .common)
        outputStream.schedule(in: .current, forMode: .common)
        
        inputStream.open()
        outputStream.open()
        sleep(3)
        sendGetRequest()
        
    }
   
    
    func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        switch eventCode {
        case .openCompleted:
            if aStream == outputStream {
                print("Output stream opened successfully")
                
                
            }
        case .hasBytesAvailable:
            if aStream == inputStream {
                var buffer = [UInt8](repeating: 0, count: 4096)
                while inputStream!.hasBytesAvailable {
                    let bytesRead = inputStream!.read(&buffer, maxLength: buffer.count)
                    if bytesRead >= 0 {
                        let data = Data(bytes: buffer, count: bytesRead)
                        print("stream: \(data)")
                        
                    }
                }
            }
        case .errorOccurred:
            print("Stream error occurred")
        case .endEncountered:
            print("close")
            close()
        default:
            break
        }
    }
    
    func sendGetRequest() {
        let credentials = "\(username):\(password)"
        guard let credentialsData = credentials.data(using: .utf8) else {
            print("Failed to encode credentials")
            return
        }
        let base64Credentials = credentialsData.base64EncodedString()
        
        let requestString = "GET /\(mountPoint) HTTP/1.0\r\n" +
        "User-Agent: NTRIP iOS Client\r\n" +
        "Authorization: Basic \(base64Credentials)\r\n" +
        "Connection: close\r\n\r\n"
        
        guard let data = requestString.data(using: .utf8) else {
            print("Failed to encode request string")
            return
        }
        
        print("Request String:\n\(requestString)") // Print the request string for debugging
        
        guard let outputStream = outputStream else {
            print("Output stream is nil")
            return
        }
        
        if outputStream.streamStatus == .open {
            let bytesWritten = data.withUnsafeBytes { outputStream.write($0.bindMemory(to: UInt8.self).baseAddress!, maxLength: data.count) }
            if bytesWritten == -1 {
                print("Failed to write to output stream: \(String(describing: outputStream.streamError))")
            } else {
                print("Successfully wrote \(bytesWritten) bytes to output stream")
            }
        } else {
            print("Output stream is not open, current status: \(outputStream.streamStatus.rawValue)")
        }
    }
    
    private func close() {
        inputStream.close()
        outputStream.close()
        inputStream.remove(from: .current, forMode: .default)
        outputStream.remove(from: .current, forMode: .default)
        inputStream = nil
        outputStream = nil
    }
    
}

extension ViewController {
    func style() {
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 20
        
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Welcome"
        label.font = UIFont.preferredFont(forTextStyle: .title1)
        
        connectButton.translatesAutoresizingMaskIntoConstraints = false
        connectButton.setTitle("Connect", for: .normal)
        connectButton.addTarget(self, action: #selector(connect), for: .touchUpInside)
        
    }
    
    func layout() {
        stackView.addArrangedSubview(label)
        stackView.addArrangedSubview(connectButton)
        
        view.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    
}
