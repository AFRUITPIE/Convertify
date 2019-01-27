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

    var id: String?
    var name: String?
    var artist: String?
    var type: String?
    var url: String?

    // Storefront for ID, see Apple Music API docs for list of storefronts
    private var storefront: String? = "us"

    // Headers for API calls
    private let headers: HTTPHeaders = ["Authorization": "Bearer \(Auth.appleMusicKey)"]

    /// Searches Apple Music from a link and parses the data accordingly
    ///
    /// - Parameter link: Apple Music link to search
    /// - Returns: DataRequest from querying Apple Music
    func search(link: String, completion: @escaping (Error?) -> Void) {
        // Reset these fields
        id = nil
        name = nil
        artist = nil
        type = nil
        storefront = nil

        // Get the data out of the link, since many links include names to data
        parseLinkData(link: link)

        // Request the search results from Apple Music
        Alamofire.request("https://api.music.apple.com/v1/catalog/\(storefront ?? "us")/\(type!)s/\(id!)", headers: headers)
            .validate()
            .responseJSON { response in
                switch response.result {
                case .success: do {
                    let data = JSON(response.result.value!)["data"][0]["attributes"]

                    self.name = data["name"].stringValue

                    // Only set artist name if artist isn't the type
                    if self.type != "artist" {
                        self.artist = data["artistName"].stringValue
                    }

                    completion(nil)
                }

                case let .failure(error): do { completion(error) }
                }
            }
    }

    /// Parses data such as id, type, and url from an Apple Music link
    ///
    /// - Parameter link: link to parse data from
    private func parseLinkData(link: String) {
        url = link
        // Get the storefront
        storefront = String(link.replacingOccurrences(of: SearcherURL.appleMusic, with: "")
            .split(separator: "/")[0])

        // Gets the "meat" of the URL
        let linkData = link.replacingOccurrences(of: "\(SearcherURL.appleMusic)\(storefront ?? "us")/", with: "")
            .split(separator: "/")

        // Gets type
        type = String(linkData[0])

        // Handles "album" and "album -> song" issue
        if type == "artist" {
            id = String(linkData[2])
        } else if type == "album" {
            // If there's an equal sign in the link, it's a SONG within an album
            if link.split(separator: "=").count == 2 {
                id = String(link.split(separator: "=")[1])
                type = "song"
            } else {
                id = String(linkData[2])
            }
        }
    }

    /// Searches Apple Music for a certain type for a query
    ///
    /// - Parameters:
    ///   - name: Name of the thing to search for in Apple Music
    ///   - type: Type to search for (example: artist)
    ///   - completion: Function to run after search is complete
    func search(name: String, type: String, completion: @escaping (Error?) -> Void) {
        // Reset URL
        url = nil

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
                        self.url = data[appleMusicType]["data"][0]["attributes"]["url"].stringValue
                        completion(nil)
                    } else {
                        // None found, let's throw an error
                        completion(MusicSearcherErrors.noSearchResultsError)
                    }
                }

                case let .failure(error): do { completion(error) }
                }
            }
    }

    /// Opens the URL in Apple Music
    func open() {
        if url != nil {
            UIApplication.shared.open(URL(string: url!)!, options: [:])
        }
    }
}
