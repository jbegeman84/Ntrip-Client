//
//  NtripHandler.swift
//  Ntrip-Client
//
//  Created by Justin Begeman on 7/15/24.
//

import Foundation

class NtripHandler: NSObject, StreamDelegate {
    var inputStream: InputStream?
    var outputStream: OutputStream?
    var casterAddress: String
    var port: Int
    var username: String
    var password: String
    var mountPoint: String
    var sendNMEA: Bool
    var mountPoints: [String] = []
    
    var completion: ((Bool, String) -> Void)?
    var mountPointCompletion: ((Bool, [String]?, String) -> Void)?
    
    init(casterAddress: String, port: Int, username: String, password: String, mountPoint: String, sendNMEA: Bool) {
        self.casterAddress = casterAddress
        self.port = port
        self.username = username
        self.password = password
        self.mountPoint = mountPoint
        self.sendNMEA = sendNMEA
    }
    
    func connect(completion: @escaping (Bool, String) -> Void) {
        self.completion = completion
        
        var readStream: Unmanaged<CFReadStream>?
        var writeStream: Unmanaged<CFWriteStream>?
        
        CFStreamCreatePairWithSocketToHost(nil, casterAddress as CFString, UInt32(port), &readStream, &writeStream)
        
        inputStream = readStream?.takeRetainedValue()
        outputStream = writeStream?.takeRetainedValue()
        
        guard let inputStream = inputStream, let outputStream = outputStream else {
            completion(false, "Failed to create streams")
            return
        }
        
        inputStream.delegate = self
        outputStream.delegate = self
        
        inputStream.schedule(in: .current, forMode: .default)
        outputStream.schedule(in: .current, forMode: .default)
        
        inputStream.open()
        outputStream.open()
    }
    
    func disconnect() {
        inputStream?.close()
        outputStream?.close()
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
                        processReceivedData(data)
                    }
                }
            }
        case .errorOccurred:
            print("Stream error occurred")
            completion?(false, "Stream error occurred")
            mountPointCompletion?(false, nil, "Stream error occurred")
        case .endEncountered:
            disconnect()
        default:
            break
        }
    }
    
    func processReceivedData(_ data: Data) {
        if let dataString = String(data: data, encoding: .utf8) {
            print("Received Data: \(dataString)")
            if dataString.contains("SOURCETABLE") {
                parseMountPoints(from: dataString)
                mountPointCompletion?(true, mountPoints, "Mount points retrieved")
            } else {
                completion?(true, "Connected to NTRIP caster")
            }
        } else {
            print("Received Data: \(data)")
            completion?(false, "Received unknown data")
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
    
    func fetchMountPoints(completion: @escaping (Bool, [String]?, String) -> Void) {
        self.mountPointCompletion = completion
        connect(completion: { (success, message) in
            if !success {
                completion(false, nil, message)
            }
        })
    }
}
