//
//  getToken.swift
//  ChatExample
//
//  Created by DIPAK KUMAR SISODIYA on 18/03/21.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import Foundation

enum tokenError:Error{
    case noDataAvailable
    case cannotProcessData
}
struct tokenRequest {
    let resourceURL:URL
    
    init(){
        let resourceString = "https://api.sariska.io/api/v1/misc/generate-token"
        guard  let resourceURL = URL(string: resourceString) else {
            fatalError()
        }
        self.resourceURL = resourceURL
    }
    
    func getToken(completion: @escaping (Result<String, tokenError>) -> Void){
 
        let json: [String: Any] = ["apiKey": "24926faa88ca145d7466c2e123aca790768002ff8faf338e29ca"]
        let body = try? JSONSerialization.data(withJSONObject: json)
        var request = URLRequest(url: resourceURL)
        request.httpMethod = "POST"
        request.httpBody = body
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        let session = URLSession.shared
        
        let dataTask = session.dataTask(with: request){data, response, error in
            guard let jsonData = data else {
                completion(.failure(.noDataAvailable))
                return
            }
            let decoder = JSONDecoder()
            if let decodedResponse = try?
                decoder.decode(Token.self, from: jsonData){
                print(decodedResponse.token)
                completion(.success(decodedResponse.token))
            }
        }
        dataTask.resume()
    }
}
