//
//  MusicSearcher.swift
//  Convertify
//
//  Created by Hayden Hong on 9/6/18.
//  Copyright © 2018 Hayden Hong. All rights reserved.
//

import Alamofire
import Foundation

protocol MusicSearcher {
    // The name of the service
    var serviceName: String { get }

    // Product color of the service
    var serviceColor: UIColor { get }

    // Authentication token of the service
//    var token: String? { get set }

    // Metadata for current searcher results
    var id: String? { get }
    var name: String? { get }
    var artist: String? { get }
    var type: String? { get }
    var url: String? { get }

    // Search using a link to get the data from it
    func search(link: String, completion: @escaping (Error?) -> Void)

    // Search using the name and type to get the link of it
    func search(name: String, type: String, completion: @escaping (Error?) -> Void)
    func open()
}

enum MusicSearcherErrors: Error {
    case noSearchResultsError
    case authenticationError
}
