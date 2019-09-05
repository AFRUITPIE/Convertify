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

public class SpotifySearcher: MusicSearcher {
    let serviceName: String = "Spotify"
    let serviceColor: UIColor = UIColor(red: 0.52, green: 0.74, blue: 0.00, alpha: 1.0)

    var token: String = ""

    public static func login(completion: @escaping (String?, Error?) -> Void) {
        let parameters = ["client_id": Auth.spotifyClientID,
                          "client_secret": Auth.spotifyClientSecret,
                          "grant_type": "client_credentials"]

        var urlComponents: URLComponents {
            var urlComponents = URLComponents()
            urlComponents.scheme = "https"
            urlComponents.host = "accounts.spotify.com"
            urlComponents.path = "/api/token"
            return urlComponents
        }

        guard let url = urlComponents.url else {
            completion(nil, MusicSearcherErrors.invalidLinkFormatError)
            return
        }

        Alamofire.request(url, method: .post, parameters: parameters, headers: nil)
            .validate()
            .responseJSON { response in
                switch response.result {
                case .success: do {
                    let data = JSON(response.result.value!)
                    let token = data["access_token"].stringValue
                    completion(token, nil)
                }
                case .failure: do {
                    // Something must have gone wrong with authentication :(
                    completion(nil, MusicSearcherErrors.authenticationError)
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
    func search(link: String, completion: @escaping (String?, String?, String?, Error?) -> Void) {
        // TODO: Replace this 'of' with a variable to be used elsewhere
        let linkData = link.replacingOccurrences(of: "https://open.spotify.com/", with: "").split(separator: "/")
        if linkData.count != 2 {
            print("It looks like the link was formatted incorrectly (link = \(link)")
            completion(nil, nil, nil, MusicSearcherErrors.noSearchResultsError)
        } else {
            let type = String(linkData[0])
            let id = String(String(linkData[1]).split(separator: "?")[0])
            let headers: HTTPHeaders = ["Authorization": "Bearer \(token)"]

            var urlComponents: URLComponents {
                var urlComponents = URLComponents()
                urlComponents.scheme = "https"
                urlComponents.host = "api.spotify.com"
                urlComponents.path = "/v1/\(type)s/\(id)"
                return urlComponents
            }

            guard let url = urlComponents.url else {
                completion(nil, nil, nil, MusicSearcherErrors.invalidLinkFormatError)
                return
            }

            // Creates the request
            Alamofire.request(url, headers: headers)
                .validate()
                .responseJSON { response in
                    switch response.result {
                    case .success: do {
                        let data = JSON(response.result.value!)
                        let name = data["name"].stringValue
                        var artist: String?

                        if type != "artist" {
                            artist = data["artists"][0]["name"].stringValue
                        }

                        completion(type, name, artist, nil)
                    }

                    case let .failure(error): do { completion(nil, nil, nil, error) }
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
    func search(name: String, type: String, completion: @escaping (String?, Error?) -> Void) {
        searchHelper(name: name, type: type, retry: true) { link, error in
            completion(link, error)
        }
    }

    /// Helper for recursively retrying search, removes the "featuring" part of link
    ///
    /// - Parameters:
    ///   - name: name to search for
    ///   - type: type to search for
    ///   - retry: whether or not to retry
    ///   - completion: what to do when searching is either successful or errors
    func searchHelper(name: String, type: String, retry: Bool, completion: @escaping (String?, Error?) -> Void) {
        let convertedType = (type == "song") ? "track" : type

        let headers: HTTPHeaders = ["Authorization": "Bearer \(self.token)"]
        let parameters: Parameters = ["q": name, "type": convertedType]

        var urlComponents: URLComponents {
            var urlComponents = URLComponents()
            urlComponents.scheme = "https"
            urlComponents.host = "api.spotify.com"
            urlComponents.path = "/v1/search/"
            return urlComponents
        }

        guard let url = urlComponents.url else {
            completion(nil, MusicSearcherErrors.invalidLinkFormatError)
            return
        }

        Alamofire.request(url, parameters: parameters, headers: headers)
            .validate()
            .responseJSON { response in
                switch response.result {
                case .success: do {
                    let data = JSON(response.result.value!)["\(type == "song" ? "track" : type)s"]

                    // Ensure there are search results
                    if data["total"].intValue > 0 {
                        let link = data["items"][0]["external_urls"]["spotify"].stringValue
                        completion(link, nil)
                    } else if retry {
                        let newName = String(name.components(separatedBy: "(feat.")[0])
                            .replacingOccurrences(of: ")", with: "")
                            .replacingOccurrences(of: "&", with: "")

                        self.searchHelper(name: newName, type: type, retry: false) { link, error in
                            completion(link, error)
                        }
                    } else {
                        completion(nil, MusicSearcherErrors.noSearchResultsError)
                    }
                }

                case let .failure(error): do { completion(nil, error) }
                }
            }
    }
}
