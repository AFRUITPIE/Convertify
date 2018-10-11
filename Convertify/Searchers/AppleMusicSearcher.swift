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

public class appleMusicSearcher: MusicSearcher {
    let serviceName: String = "Apple Music"
    let serviceColor: UIColor = UIColor(red: 0.98, green: 0.34, blue: 0.76, alpha: 1.0)

    var id: String?
    var name: String?
    var artist: String?
    var type: String?
    var url: String?
    var token: String?
    private var storefront: String?

    init() {
        token = Authentication.appleMusicKey
    }

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

        let headers = ["Authorization": "Bearer \(self.token ?? "")"]

        // Request the search results from Apple Music
        Alamofire.request("https://api.music.apple.com/v1/catalog/\(storefront ?? "us")/\(type!)s/\(id!)", headers: headers)
            .validate()
            .responseJSON { response in

                switch response.result {
                case .success: do {
                    let json = response.result.value as! NSDictionary

                    // Gets the meaty data that we want from the JSON
                    let data: AnyObject = (((json.object(forKey: "data") as! NSArray)[0]) as AnyObject)
                        .object(forKey: "attributes") as AnyObject

                    // Gets the name from the JSON
                    self.name = data.object(forKey: "name") as? String

                    // Gets the artist from the JSON
                    if self.type != "artist" {
                        self.artist = data.object(forKey: "artistName") as? String
                    }

                    // Finally, run the completion with no errors
                    completion(nil)
                }

                case let .failure(error): do {
                    completion(error)
                }
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
                id = String(linkData[2]) // FIXME: Horrific style you asshole
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
        url = nil

        let appleMusicType = type == "track" ? "songs" : "\(type)s"
        let parameters: Parameters = ["term": name,
                                      "types": appleMusicType]
        let headers: HTTPHeaders = ["Authorization": "Bearer \(Authentication.appleMusicKey)"]

        Alamofire.request("https://api.music.apple.com/v1/catalog/\(storefront ?? "us")/search", parameters: parameters, headers: headers)
            .validate()
            .responseJSON { response in
                switch response.result {
                case .success: do {
                    let json = response.result.value as! NSDictionary

                    let results = json.object(forKey: "results") as! NSDictionary

                    // Ensures there are search results
                    if results.value(forKey: appleMusicType) != nil {
                        self.url = ((((results
                                .object(forKey: appleMusicType) as AnyObject)
                                .object(forKey: "data") as! NSArray)[0] as AnyObject)
                            .object(forKey: "attributes") as AnyObject)
                            .object(forKey: "url") as? String
                        completion(nil)
                    } else {
                        completion(MusicSearcherErrors.noSearchResultsError)
                    }
                }

                case let .failure(error): do {
                    completion(error)
                }
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
