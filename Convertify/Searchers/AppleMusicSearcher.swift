//
//  AppleMusicSearcher.swift
//  Spotify to Apple Music
//
//  Handles Spotify querying and maintains information about Spotify
//
//  Created by Hayden Hong on 8/6/18.
//  Copyright © 2018 Hayden Hong. All rights reserved.
//

import Alamofire
import Foundation
import SwiftyJSON

public class appleMusicSearcher: MusicSearcher {
    let serviceName: String = "Apple Music"
    let serviceColor: UIColor = UIColor(red: 0.98, green: 0.34, blue: 0.76, alpha: 1.0)

    // Storefront for ID, see Apple Music API docs for list of storefronts
    private var storefront: String? = "us"

    // Headers for API calls
    private let headers: HTTPHeaders = ["Authorization": "Bearer \(Auth.appleMusicKey)"]

    /// Searches Apple Music from a link and parses the data accordingly
    ///
    /// - Parameter link: Apple Music link to search
    /// - Returns: DataRequest from querying Apple Music
    func search(link: String, completion: @escaping (String?, String?, String?, Error?) -> Void) {
        // Get the data out of the link, since many links include names to data
        let type = getType(from: link)
        let id = getID(from: link)
        storefront = getStorefront(from: link)

        print("\(type), \(id), \(storefront ?? "")")

        // Request the search results from Apple Music
        Alamofire.request("https://api.music.apple.com/v1/catalog/\(storefront ?? "us")/\(type)s/\(id)", headers: headers)
            .validate()
            .responseJSON { response in
                switch response.result {
                case .success: do {
                    let data = JSON(response.result.value!)["data"][0]["attributes"]

                    let name = data["name"].stringValue
                    var artist: String?

                    // Only set artist name if artist isn't the type
                    if type != "artist" {
                        artist = data["artistName"].stringValue
                    }

                    completion(type, name, artist, nil)
                }

                case let .failure(error): do { completion(nil, nil, nil, error) }
                }
            }
    }

    /// Parses the type from an Apple Music Link
    ///
    /// - Parameter from: Apple Music Link to get type  from
    /// - Returns: type
    private func getType(from: String) -> String {
        if from.split(separator: "=").count == 2 {
            return "song"
        } else {
            return String(from.replacingOccurrences(of: "\(SearcherURL.appleMusic)\(storefront ?? "us")/", with: "")
                .split(separator: "/")[0])
        }
    }

    /// Parses the storefront code from an Apple Music Link
    ///
    /// - Parameter from: Apple Music Link to get storefront code from
    /// - Returns: storefront code
    private func getStorefront(from: String) -> String {
        return String(from.replacingOccurrences(of: SearcherURL.appleMusic, with: "")
            .split(separator: "/")[0])
    }

    /// Parses the ID from an Apple Music Link
    ///
    /// - Parameter from: Apple Music Link to get ID from
    /// - Returns: ID
    private func getID(from: String) -> String {
        // Gets the "meat" of the URL
        let linkData = from.split(separator: "/")

        if getType(from: from) != "song" {
            return String(linkData[linkData.count - 1])
        } else {
            return String(linkData[linkData.count - 1].components(separatedBy: "?i=")[1])
        }
    }

    /// Searches Apple Music for a certain type for a query
    ///
    /// - Parameters:
    ///   - name: Name of the thing to search for in Apple Music
    ///   - type: Type to search for (example: artist)
    ///   - completion: Function to run after search is complete
    func search(name: String, type: String, completion: @escaping (String?, Error?) -> Void) {
        search(name: name, type: type, retry: true) { link, error in
            completion(link, error)
        }
    }

    /// Recursive helper function for doing search
    ///
    /// - Parameters:
    ///   - name: name of resource
    ///   - type: type of resource
    ///   - retry: whether or not to retry
    ///   - completion: what to do with the link/error when done
    private func search(name: String, type: String, retry: Bool, completion: @escaping (String?, Error?) -> Void) {
        let appleMusicType = type == "track" ? "songs" : "\(type)s"
        let parameters: Parameters = ["term": name,
                                      "types": appleMusicType]

        Alamofire.request("https://api.music.apple.com/v1/catalog/\(storefront ?? "us")/search", parameters: parameters, headers: headers)
            .validate()
            .responseJSON { response in
                switch response.result {
                case .success: do {
                    let data = JSON(response.result.value!)["results"]

                    // Ensures there are search results before setting it
                    if data[appleMusicType].exists() {
                        let link = data[appleMusicType]["data"][0]["attributes"]["url"].stringValue
                        completion(link, nil)
                    } else {
                        // Redo search
                        if retry {
                            let newName = String(name.components(separatedBy: " - ")[0])
                            self.search(name: newName, type: type, retry: false) { link, error in
                                completion(link, error)
                            }
                        }
                        // None found, let's throw an error
                        completion(nil, MusicSearcherErrors.noSearchResultsError)
                    }
                }
                case let .failure(error): do { completion(nil, error) }
                }
            }
    }
}
