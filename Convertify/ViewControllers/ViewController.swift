//
//  ViewController.swift
//  Convertify
//
//  Created by Hayden Hong on 8/7/18.
//  Copyright © 2018 Hayden Hong. All rights reserved.
//

import Alamofire
import Pastel
import SpotifyLogin
import UIKit

class ViewController: UIViewController {
    private var appleMusic: MusicSearcher!
    private var spotify: MusicSearcher!

    private var link: String?

    // Mark: Properties

    @IBOutlet var convertButton: UIButton!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var activityMonitor: UIActivityIndicatorView!
    var pastelView: PastelView!

    // Mark: Functions

    func initApp(link: String) {
        self.link = link
        spotify = spotifySearcher { error in
            if error == nil {
                // Start the search using the new Apple Music object
                self.appleMusic = appleMusicSearcher()
                self.handleLink(link: self.link ?? "")
            } else {
                // Display an error for logging in
                self.updateAppearance(title: "Error getting Spotify credentials", color: UIColor.red, enabled: false)
            }
        }
    }

    override func viewDidLoad() {
        pastelView = PastelView(frame: view.bounds)
    }

    /// Animates the color conversion in the app
    ///
    /// - Parameters:
    ///   - title: Name to set the label to
    ///   - color: Color to set the background to
    ///   - enabled: Whether or not the convert button should be shown
    private func updateAppearance(title: String, color: UIColor, enabled: Bool) {
        convertButton.setTitle(title, for: .normal)
        // Animate color shift
        UIView.animate(withDuration: 3.0, delay: 0.0, options: [.allowUserInteraction], animations: {
            self.titleLabel.textColor = UIColor.white
            self.view.backgroundColor = color
            self.convertButton.setTitleColor(UIColor.white, for: .normal)
        })

        convertButton.isEnabled = enabled
    }

    /// "Connects" Apple Music and Spotify for searching between them. Finds matching
    /// data from opposite source and allows the user to open links in opposite app.
    ///
    /// - Parameter link: Link to handle
    func handleLink(link: String) {
        // Resets the label text while converting
        titleLabel.text = "Convertify"

        // Decides what to do with the link
        switch true {
        // Ignores playlists
        case link.contains("/playlist/"):
            if link.contains("open.spotify.com") {
                handlePlaylistConversion(link: link)
            } else if link.contains("itunes.apple.com") {
                handleSpotifyPlaylistConversion(link: link)
            } else {
                updateAppearance(title: "I don't recognize where that playlist is from ☹️", color: UIColor.red, enabled: false)
            }

        // Ignores radio stations
        case link.contains("/station/"):
            updateAppearance(title: "I cannot convert radio stations ☹️", color: UIColor.red, enabled: false)

        // Extracts Spotify data and searches for Apple Music links when it includes a Spotify link
        case link.contains(SearcherURL.spotify):
            handleSearching(link: link, source: spotify, destination: appleMusic)

        // Extracts Apple Music data and searches for Spotify links when it includes an Apple Music link
        case link.contains(SearcherURL.appleMusic):
            handleSearching(link: link, source: appleMusic, destination: spotify)

        // Lets the user know I don't know how to handle whatever is in their clipboard
        default:
            updateAppearance(title: "No Spotify or Apple Music link found in clipboard", color: UIColor.gray, enabled: false)
        }
    }

    /// Handles searching between the source and destination
    ///
    /// - Parameters:
    ///   - link: link to search with
    ///   - source: Source service of the link
    ///   - destination: Destination to open the search result in
    private func handleSearching(link: String, source: MusicSearcher, destination: MusicSearcher) {
        // Create feedback generator for stuff
        var feedbackGenerator: UINotificationFeedbackGenerator? = UINotificationFeedbackGenerator()
        feedbackGenerator?.prepare()

        // Search the source
        source.search(link: link) { type, name, artist, error in
            print("Searching \(source.serviceName) \(error == nil ? "successful" : "failed")")

            if error == nil {
                self.titleLabel.text = (artist == nil ? name! : name! + " by " + artist!)

                destination.search(name: name! + " " + (artist ?? ""), type: type!) { link, error in
                    print("Searching \(destination.serviceName) \(error == nil ? "successful" : "failed")")
                    // Update some of the visible parts of the app to show it is NOT loading
                    if error == nil {
                        self.link = link
                        self.updateAppearance(title: "Open in \(destination.serviceName)", color: destination.serviceColor, enabled: true)
                        feedbackGenerator?.notificationOccurred(.success)
                    } else {
                        self.updateAppearance(title: "Error getting \(destination.serviceName) data", color: UIColor.red, enabled: false)
                        feedbackGenerator?.notificationOccurred(.error)
                    }
                }
            } else {
                // Display the error
                self.titleLabel.text = "Error getting \(source.serviceName) data"
                self.updateAppearance(title: "Link might be formatted incorrectly", color: UIColor.red, enabled: false)
                feedbackGenerator?.notificationOccurred(.error)
            }

            // Deallocate feedbackGenerator
            feedbackGenerator = nil
        }
    }

    /// Adds pretty animation for converting playlists
    private func addPastelView() {
        // Custom Direction
        pastelView.startPastelPoint = .bottom
        pastelView.endPastelPoint = .top

        // Custom Duration
        pastelView.animationDuration = 3.0

        // Custom Color
        pastelView.setColors([spotify.serviceColor, appleMusic.serviceColor])
        pastelView.alpha = 0.0
        UIView.animate(withDuration: 3.0, delay: 0.0, options: [.allowUserInteraction], animations: {
            self.pastelView.startAnimation()
            self.view.insertSubview(self.pastelView, at: 0)
            self.pastelView.alpha = 1.0
        })
    }

    func handleSpotifyPlaylistConversion(link: String) {
        AppleMusicPlaylistSearcher().getTrackList(link: link) { trackList, playlistName, error in

            if error == nil {
                let alert = UIAlertController(title: "Add \(playlistName ?? "") to Spotify?", message: "This playlist will be added to your Spotify library with the closest matches we can find.", preferredStyle: UIAlertController.Style.alert)

                // Yes, add the playlist
                alert.addAction(UIAlertAction(title: "Yes", style: UIAlertAction.Style.default) { _ in
                    // Show some cool animations
                    self.addPastelView()
                    self.titleLabel.text = playlistName ?? ""
                    self.updateAppearance(title: "Converting now, this might take a while", color: UIColor.darkGray, enabled: false)
                    self.handleSpotifyLogin() { token, error in
                        SpotifyPlaylistSearcher(token: token).addPlaylist(trackList: trackList!, playlistName: playlistName ?? "") { link, error in
                            if error == nil {
                                print(link!)
                                self.pastelView.removeFromSuperview()
                                UIApplication.shared.open(URL(string: link!)!, options: [:])
                            } else {
                                self.updateAppearance(title: "We had problems converting this playlist", color: UIColor.red, enabled: false)
                            }
                            self.pastelView.removeFromSuperview()
                        }
                    }
                })

                // TODO: Add a no action to the action thing

                // Show the alert
                self.present(alert, animated: true, completion: nil)
            } else {
                self.updateAppearance(title: "We had problems converting this playlist", color: UIColor.red, enabled: false)
            }
        }
    }

    private func handleSpotifyLogin(completion: @escaping (String?, Error?) -> Void) {
        SpotifyLogin.shared.getAccessToken { token, error in
            switch error {
            case nil: completion(token, error)
            default: SpotifyLoginPresenter.login(from: self, scopes: [.playlistModifyPrivate])
            }
        }
    }

    /// Does the dirty work for converting playlists
    ///
    /// - Parameter link: playlist link to handle
    func handlePlaylistConversion(link: String) {
        // FOR RIGHT NOW we can assume this will be a spotify link

        // Get the tracklist
        SpotifyPlaylistSearcher(token: nil).getTrackList(link: link) { trackList, playlistName, error in
            // Error handling
            if error == nil {
                // Alert the user about adding the playlist
                let alert = UIAlertController(title: "Add \(playlistName ?? "") to Apple Music?", message: "This playlist will be added to your Apple Music library with the closest matches we can find.", preferredStyle: UIAlertController.Style.alert)

                // Yes, add the playlist
                alert.addAction(UIAlertAction(title: "Yes", style: UIAlertAction.Style.default) { _ in
                    // Show some cool animations
                    self.addPastelView()

                    self.titleLabel.text = playlistName ?? ""
                    self.updateAppearance(title: "Converting now, this might take a while", color: UIColor.darkGray, enabled: false)
                    AppleMusicPlaylistSearcher().addPlaylist(trackList: trackList!, playlistName: playlistName ?? "") { link, error in
                        if error == nil {
                            print(link!)
                            UIApplication.shared.open(URL(string: link!)!, options: [:])
                        } else {
                            self.updateAppearance(title: "We had problems converting this playlist", color: UIColor.red, enabled: false)
                        }
                        self.pastelView.removeFromSuperview()
                    }
                })

                // TODO: Add a no action to the action thing

                // Show the alert
                self.present(alert, animated: true, completion: nil)
            } else {
                self.updateAppearance(title: "We had problems converting this playlist", color: UIColor.red, enabled: false)
            }
        }
    }

    // Mark: Actions

    /// Opens the link in the opposite app
    @IBAction func openSong(_: Any) {
        if link != nil {
            UIApplication.shared.open(URL(string: link!)!, options: [:])
        }
    }
}
