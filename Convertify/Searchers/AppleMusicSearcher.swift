//
//  AppleMusicSearcher.swift
//  Spotify to Apple Music
//
//  Created by Hayden Hong on 8/6/18.
//  Copyright © 2018 Hayden Hong. All rights reserved.
//

import Alamofire
import Foundation

/// Handles Apple Music querying and maintains information about Apple Music
public class appleMusicSearcher: MusicSearcher {
    let serviceName: String = "Apple Music"
    let serviceColor: UIColor = UIColor(red: 0.98, green: 0.34, blue: 0.76, alpha: 1.0)

    var id: String?
    var name: String?
    var artist: String?
    var type: String?
    var url: String?
    var token: String?

    init() {
        token = Authentication.appleMusicKey
    }

    /// Searches Apple Music from a link and parses the data accordingly
    ///
    /// - Parameter link: Apple Music link to search
    /// - Returns: DataRequest from querying Apple Music
    func search(link: String) -> DataRequest? {
        // Reset these fields
        id = nil
        name = nil
        artist = nil
        type = nil

        // Get the data out of the link, since many links include names to data
        parseLinkData(link: link)

        let headers = ["Authorization": "Bearer \(self.token ?? "")"]

        // Request the search results from Apple Music
        return Alamofire.request("https://api.music.apple.com/v1/catalog/us/\(type!)s/\(id ?? "")", headers: headers).responseJSON { response in
            if let result = response.result.value {
                // Gets the meaty data that we want from the JSON
                let data: AnyObject = ((((result as! NSDictionary)
                        .object(forKey: "data") as! NSArray)[0]) as AnyObject)
                    .object(forKey: "attributes") as AnyObject

                // Gets the name from the JSON
                self.name = data.object(forKey: "name") as? String

                // Gets the artist from the JSON
                if self.type != "artist" {
                    self.artist = data.object(forKey: "artistName") as? String
                }
            }
        }
    }

    /// Parses data such as id, type, and url from an Apple Music link
    ///
    /// - Parameter link: link to parse data from
    private func parseLinkData(link: String) {
        url = link
        let linkData = link.replacingOccurrences(of: "\(SearcherURL.appleMusic)us/", with: "").split(separator: "/")
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
    /// - Returns: DataRequest made from querying Apple Music
    func search(name: String, type: String, completion: @escaping (Error?) -> Void) {
        url = nil
        let safeName = name.replacingOccurrences(of: "&", with: "and").replacingOccurrences(of: " ", with: "+")
        let headers = ["Authorization": "Bearer \(Authentication.appleMusicKey)"]
        let appleMusicType = convertTypeToAppleMusicType(type: type)

        Alamofire.request("https://api.music.apple.com/v1/catalog/us/search?term=\(safeName)&types=\(appleMusicType)", headers: headers).responseJSON { response in
            if let result = response.result.value {
                let JSON = result as! NSDictionary

                let results = JSON.object(forKey: "results") as! NSDictionary

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
        }
    }

    /// Opens the URL in Apple Music
    func open() {
        if url != nil {
            UIApplication.shared.open(URL(string: url!)!, options: [:])
        }
    }

    /// Helper function for converting Spotify type to Apple Music
    ///
    /// - Parameter type: type from Spotify
    /// - Returns: type from Apple Music
    private func convertTypeToAppleMusicType(type: String) -> String {
        switch type {
        case "track":
            return "songs"
        default:
            return "\(type)s"
        }
    }
}
