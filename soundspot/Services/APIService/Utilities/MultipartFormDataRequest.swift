//
//  MultipartFormDataRequest.swift
//  soundspot
//
//  Created by Yassine Regragui on 12/1/21.
//

import Foundation

// one instance per request
struct MultipartFormDataRequest {
    private let boundary: String = UUID().uuidString
    private var httpBody = NSMutableData()
	let url: URL
	private var request: URLRequest

    init(url: URL) {
        self.url = url
		request = URLRequest(url: url)
		request.httpMethod = "POST"
		request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
    }
    

    func addTextField(named name: String, value: String) {
        httpBody.append(textFormField(named: name, value: value))
    }

    private func textFormField(named name: String, value: String) -> String {
        var fieldString = "--\(boundary)\r\n"
        fieldString += "Content-Disposition: form-data; name=\"\(name)\"\r\n"
        fieldString += "\r\n"
        fieldString += "\(value)\r\n"

        return fieldString
    }

    func addDataField(fieldName: String, fileName: String, fileData: Data, mimeType: String) {
        httpBody.append(convertFileData(fieldName: fieldName, fileName: fileName, fileData: fileData, mimeType: mimeType))
    }

    private func convertFileData(fieldName: String,
                               fileName: String,
                               fileData: Data,
                               mimeType: String) -> Data {
        let fieldData = NSMutableData()

        fieldData.append("--\(boundary)\r\n")
        fieldData.append("Content-Disposition: form-data; name=\"\(fieldName)\"; filename=\"\(fileName)\"\r\n")
        fieldData.append("Content-Type: \(mimeType)\r\n")
        fieldData.append("\r\n")
        fieldData.append(fileData)
        fieldData.append("\r\n")
        
        return fieldData as Data
    }
	
	mutating func getFinalRequest() -> URLRequest{
		httpBody.append("--\(boundary)--")
		request.httpBody = httpBody as Data
		return request
	}
}

// Move to extensions file
extension NSMutableData {
  func append(_ string: String) {
    if let data = string.data(using: .utf8) {
      self.append(data)
    }
  }
}
