//
//  SpotifySearcher.swift
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

public class spotifySearcher: MusicSearcher {
    let serviceName: String = "Spotify"
    let serviceColor: UIColor = UIColor(red: 0.52, green: 0.74, blue: 0.00, alpha: 1.0)

    var id: String?
    var name: String?
    var artist: String?
    var type: String?
    var url: String?

    private var token: String?

    /// Generate a token
    init(completion: @escaping (Error?) -> Void) {
        let parameters = ["client_id": Auth.spotifyClientID,
                          "client_secret": Auth.spotifyClientSecret,
                          "grant_type": "client_credentials"]

        Alamofire.request("https://accounts.spotify.com/api/token", method: .post, parameters: parameters, headers: nil)
            .validate()
            .responseJSON { response in
                switch response.result {
                case .success: do {
                    let data = JSON(response.result.value!)
                    self.token = data["access_token"].stringValue
                    completion(nil)
                }

                case .failure: do {
                    // Something must have gone wrong with authentication :(
                    completion(MusicSearcherErrors.authenticationError)
                }
                }
            }
    }

    /// Use a provided token
    init(token: String) {
        self.token = token
    }

    /// Searches the Spotify API from a link and extracs the information from it
    ///
    /// - Parameter link: Link to search for within the Spotify API
    /// - Parameter completion: What to run after searching is complete
    /// - Returns: DataRequest from querying the Spotify API
    func search(link: String, completion: @escaping (Error?) -> Void) {
        // Reset these variables
        id = nil
        name = nil
        artist = nil
        type = nil

        let linkData = link.replacingOccurrences(of: SearcherURL.spotify, with: "").split(separator: "/")
        if linkData.count != 2 {
            print("It looks like the link was formatted incorrectly (link = \(link)")
            completion(MusicSearcherErrors.noSearchResultsError)
        } else {
            type = String(linkData[0])
            id = String(String(linkData[1]).split(separator: "?")[0])
            let headers: HTTPHeaders = ["Authorization": "Bearer \(token!)"]

            // Creates the request
            Alamofire.request("https://api.spotify.com/v1/\(type!)s/\(id!)", headers: headers)
                .validate()
                .responseJSON { response in
                    switch response.result {
                    case .success: do {
                        let data = JSON(response.result.value!)
                        self.name = data["name"].stringValue

                        if self.type != "artist" {
                            self.artist = data["artists"][0]["name"].stringValue
                        }

                        // Run completion with no errors
                        completion(nil)
                    }

                    case let .failure(error): do { completion(error) }
                    }
                }
        }
    }

    /// Searches Spotify for the name and type
    ///
    /// - Parameters:
    ///   - name: Name of resource to search for
    ///   - type: Type of resource to search for
    ///   - completion: What to run after searching is complete
    /// - Returns: DataRequest from the Spotify API
    func search(name: String, type: String, completion: @escaping (Error?) -> Void) {
        self.type = type == "song" ? "track" : type

        let headers: HTTPHeaders = ["Authorization": "Bearer \(self.token ?? "")"]
        let parameters: Parameters = ["q": name, "type": self.type!]

        Alamofire.request("https://api.spotify.com/v1/search/", parameters: parameters, headers: headers)
            .validate()
            .responseJSON { response in
                switch response.result {
                case .success: do {
                    let data = JSON(response.result.value!)[(self.type ?? "") + "s"]

                    // Ensure there are search results
                    if data["total"].intValue > 0 {
                        self.url = data["items"][0]["external_urls"]["spotify"].stringValue
                        completion(nil)
                    } else {
                        // TODO: Start implementing redo here

                        completion(MusicSearcherErrors.noSearchResultsError)
                    }
                }

                case let .failure(error): do { completion(error) }
                }
            }
    }

    /// Opens the URL
    func open() {
        if url != nil {
            UIApplication.shared.open(URL(string: url!)!, options: [:])
        }
    }
}
