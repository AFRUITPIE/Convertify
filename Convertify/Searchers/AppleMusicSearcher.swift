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
import CupertinoJWT
import Foundation
import SwiftyJSON

public class AppleMusicSearcher: MusicSearcher {
    let serviceName: String = "Apple Music"
    var token: String = ""
    let serviceColor: UIColor = UIColor(red: 0.98, green: 0.34, blue: 0.76, alpha: 1.0)

    // Storefront for ID, see Apple Music API docs for list of storefronts
    private lazy var storefront: String = "us"

    // Headers for API calls
    private lazy var headers: HTTPHeaders = [:]

    
    public static func login(completion: @escaping (String?, Error?) -> Void) {
        // Assign developer information and token expiration setting
        let jwt = JWT(keyID: Auth.appleKeyID, teamID: Auth.appleTeamID, issueDate: Date(), expireDuration: 60 * 60)

        do {
            let token = try jwt.sign(with: Auth.appleP8)
            completion(token, nil)
        } catch {
            completion(nil, MusicSearcherErrors.authenticationError)
            // Handle error
        }
    }

    init(token: String) {
        self.token = token
        headers = ["Authorization": "Bearer \(token)"]
    }

    /// Searches Apple Music from a link and parses the data accordingly
    ///
    /// - Parameter link: Apple Music link to search
    /// - Returns: DataRequest from querying Apple Music
    func search(link: String, completion: @escaping (String?, String?, String?, Error?) -> Void) {
        // Get the data out of the link, since many links include names to data
        var type: String = ""
        var id: String = ""

        do {
            type = try getType(from: link)
            id = try getID(from: link, type: type)
            storefront = try getStorefront(from: link)
        } catch {
            completion(nil, nil, nil, error)
            return
        }

        var urlComponents: URLComponents {
            var urlComponents = URLComponents()
            urlComponents.scheme = "https"
            urlComponents.host = "api.music.apple.com"
            urlComponents.path = "/v1/catalog/\(storefront)/\(type)s/\(id)"
            return urlComponents
        }

        guard let url = urlComponents.url else {
            completion(nil, nil, nil, MusicSearcherErrors.invalidLinkFormatError)
            return
        }

        // Request the search results from Apple Music
        AF.request(url, headers: headers)
            .validate()
            .responseJSON { response in
                switch response.result {
                case .success: do {
                    guard let value = response.value else {
                        completion(nil, nil, nil, MusicSearcherErrors.invalidLinkFormatError)
                        return
                    }

                    let data = JSON(value)["data"][0]["attributes"]

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
    private func getType(from: String) throws -> String {
        if let components = URLComponents(string: from) {
            if components.queryItems != nil {
                return "song"
            } else {
                return String(components.path.split(separator: "/")[1])
            }
        }
        throw MusicSearcherErrors.invalidLinkFormatError
    }

    /// Parses the storefront code from an Apple Music Link
    ///
    /// - Parameter from: Apple Music Link to get storefront code from
    /// - Returns: storefront code
    private func getStorefront(from: String) throws -> String {
        if let components = URLComponents(string: from) {
            return String(components.path.split(separator: "/")[0])
        }
        throw MusicSearcherErrors.invalidLinkFormatError
    }

    /// Parses the ID from an Apple Music Link
    ///
    /// - Parameter from: Apple Music Link to get ID from
    /// - Parameter type: type of resource the link is for
    /// - Returns: ID
    private func getID(from: String, type: String) throws -> String {
        if let components = URLComponents(string: from) {
            if type != "song" {
                return String(components.path.split(separator: "/").last!)
            } else {
                if !(components.queryItems?.isEmpty ?? true) {
                    return components.queryItems?[0].value ?? ""
                } else {
                    return ""
                }
            }
        }
        throw MusicSearcherErrors.invalidLinkFormatError
    }

    /// Searches Apple Music for a certain type for a query
    ///
    /// - Parameters:
    ///   - name: Name of the thing to search for in Apple Music
    ///   - type: Type to search for (example: artist)
    ///   - completion: Function to run after search is complete
    func search(name: String, type: String, completion: @escaping (String?, Error?) -> Void) {
        searchHelper(name: name, type: type, retry: true) { link, error in
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
    private func searchHelper(name: String, type: String, retry: Bool, completion: @escaping (String?, Error?) -> Void) {
        let appleMusicType = type == "track" ? "songs" : "\(type)s"
        let parameters: Parameters = ["term": name,
                                      "types": appleMusicType]

        var urlComponents: URLComponents {
            var urlComponents = URLComponents()
            urlComponents.scheme = "https"
            urlComponents.host = "api.music.apple.com"
            urlComponents.path = "/v1/catalog/\(storefront)/search"
            return urlComponents
        }

        guard let url = urlComponents.url else {
            completion(nil, MusicSearcherErrors.invalidLinkFormatError)
            return
        }

        AF.request(url, parameters: parameters, headers: headers)
            .validate()
            .responseJSON { response in
                switch response.result {
                case .success: do {
                    let data = JSON(response.value!)["results"]

                    // Ensures there are search results before setting it
                    if data[appleMusicType].exists() {
                        let link = data[appleMusicType]["data"][0]["attributes"]["url"].stringValue
                        completion(link, nil)
                    } else if retry {
                        guard let featStart = name.firstIndex(of: "(") else {
                            print("Nothing in parentheses for \(name), not attempting retry")
                            completion(nil, MusicSearcherErrors.noSearchResultsError)
                            return
                        }

                        guard let featEnd = name.lastIndex(of: ")") else {
                            print("Nothing in parentheses for \(name), not attempting retry")
                            completion(nil, MusicSearcherErrors.noSearchResultsError)
                            return
                        }

                        let nameBeforeFeat = name[..<featStart] + name[name.index(after: featEnd)...]
                        print("Retrying search for \(name) with \(nameBeforeFeat)")

                        self.searchHelper(name: String(nameBeforeFeat), type: type, retry: false) { link, error in
                            completion(link, error)
                        }
                    } else {
                        // None found, let's throw an error
                        completion(nil, MusicSearcherErrors.noSearchResultsError)
                    }
                }
                case let .failure(error): do { completion(nil, error) }
                }
            }
    }
}
