//
//  NtripClient.swift
//  NTRIP
//
//  Created by Justin Begeman on 7/8/24.
//

import Foundation

protocol NtripClientDelegate: AnyObject {
    func received(message: Message)
}

class NtripClient: NSObject {
    
    var inputStream: InputStream!
    var outputStream: OutputStream!
    
    var casterAddress: String
    var port: Int
    var username: String
    var password: String
    var mountPoint: String
    var mountPoints: [String] = []
    
    weak var delegate: NtripClientDelegate?
    
    
    init(casterAddress: String, port: Int, username: String, password: String, mountPoint: String) {
        self.casterAddress = casterAddress
        self.port = port
        self.username = username
        self.password = password
        self.mountPoint = mountPoint
    }
    
    func connect() {
        
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


extension NtripClient: StreamDelegate {
    
    func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        switch eventCode {
        case .openCompleted:
            if aStream == outputStream {
                print("Output stream opened successfully")
                sendGetRequest()
            }
        case .hasBytesAvailable:
            if aStream == inputStream {
                var buffer = [UInt8](repeating: 0, count: 4096)
                while inputStream!.hasBytesAvailable {
                    let bytesRead = inputStream!.read(&buffer, maxLength: buffer.count)
                    if bytesRead >= 0 {
                        let data = Data(bytes: buffer, count: bytesRead)
                        print("stream: \(data)")
                        processReceivedData(data)
                    }
                }
            }
        case .errorOccurred:
            print("Stream error occurred")
        case .endEncountered:
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
    
    func processReceivedData(_ data: Data) {
        if let dataString = String(data: data, encoding: .utf8) {
            print("Received Data: \(dataString)")
            if dataString.contains("SOURCETABLE") {
                parseMountPoints(from: dataString)
            } else {
                print("Received Data: \(data)")
            }
        }
    }
    
    func parseMountPoints(from response: String) {
        let lines = response.split(separator: "\n")
        mountPoints.removeAll()
        for line in lines {
            if line.starts(with: "STR;") {
                let components = line.split(separator: ";")
                if components.count > 1 {
                    mountPoints.append(String(components[1]))
                }
            }
        }
    }
}

struct Message {
    let message: String
    let senderVM: String

    init(message: String, senderVM: String) {
      self.message = message
      self.senderVM = senderVM
    }
}
