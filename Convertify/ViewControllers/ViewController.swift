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

class ViewController: UIViewController, UITextFieldDelegate {
    private var appleMusic: MusicSearcher!
    private var spotify: MusicSearcher!
    private var link: String?
    private var playlistTracks: [PlaylistTrack] = []
    private var failedToConvertTracks: [PlaylistTrack] = []

    // MARK: Properties

    @IBOutlet var convertButton: UIButton!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var linkTextField: UITextField!
    @IBOutlet var helpButton: UIButton!

    var pastelView: PastelView!

    // MARK: Functions

    override func viewDidLoad() {
        pastelView = PastelView(frame: view.bounds)
        // Allow multiple lines
        convertButton.titleLabel?.numberOfLines = 0
        // Close keyboard on background click
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard(_:)))
        view.addGestureRecognizer(tapGesture)
        initApp()
    }

    func initApp() {
        // Ensure Spotify has credentials
        SpotifySearcher.login { spotifyToken, _ in
            guard let spotifyToken = spotifyToken else {
                // Display an error for logging in
                self.updateAppearance(title: "Error getting Spotify credentials", color: UIColor.red, enabled: false)
                return
            }
            self.spotify = SpotifySearcher(token: spotifyToken)

            // Ensure Apple Music has credentials
            AppleMusicSearcher.login { appleMusicToken, _ in
                guard let appleMusicToken = appleMusicToken else {
                    self.updateAppearance(title: "Error getting Apple Music credentials", color: UIColor.red, enabled: false)
                    return
                }
                self.appleMusic = AppleMusicSearcher(token: appleMusicToken)

                // Force UI update
                self.handleLink(link: "")
            }
        }
    }

    // Hide toolbar
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    // Show toolbar when hidden
    override func viewWillDisappear(_ animated: Bool) {
        navigationController?.setNavigationBarHidden(false, animated: animated)
        super.viewWillDisappear(animated)
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
    private func handleLink(link: String) {
        // Resets the label text while converting
        titleLabel.text = "Convertify"

        // Decides what to do with the link
        switch true {
        // Converts playlists
        case link.range(of: SearcherURL.playlist, options: [.regularExpression, .anchored]) != nil:
            handlePlaylist(link: link)

        // Ignores radio stations
        case link.contains("/station/"):
            updateAppearance(title: "I cannot convert radio stations ☹️", color: UIColor.red, enabled: false)

        // Extracts Spotify data and searches for Apple Music links when it includes a Spotify link
        case link.range(of: SearcherURL.spotify, options: [.regularExpression, .anchored]) != nil:
            handleSearching(link: link, source: spotify, destination: appleMusic)

        // Extracts Apple Music data and searches for Spotify links when it includes an Apple Music link
        case link.range(of: SearcherURL.appleMusic, options: [.regularExpression, .anchored]) != nil:
            handleSearching(link: link, source: appleMusic, destination: spotify)

        // Lets the user know I don't know how to handle whatever is in their clipboard
        default:
            updateAppearance(title: "No music link detected", color: UIColor.gray, enabled: false)
        }
    }

    /// Handles searching between the source and destination
    ///
    /// - Parameters:
    ///   - link: link to search with
    ///   - source: Source service of the link
    ///   - destination: Destination to open the search result in
    private func handleSearching(link: String, source: MusicSearcher, destination: MusicSearcher) {
        // Search the source
        source.search(link: link) { type, name, artist, error in
            if error == nil {
                self.titleLabel.text = (artist == nil ? name! : name! + " by " + artist!)

                destination.search(name: name! + " " + (artist ?? ""), type: type!) { link, error in
                    print("Searching \(destination.serviceName) \(error == nil ? "successful" : "failed")")
                    // Update some of the visible parts of the app to show it is NOT loading
                    if error == nil {
                        self.link = link
                        self.updateAppearance(title: "Open in \(destination.serviceName)", color: destination.serviceColor, enabled: true)
                    } else {
                        self.updateAppearance(title: "Error getting \(destination.serviceName) data", color: UIColor.darkGray, enabled: false)
                    }
                }
            } else {
                // Display the error
                self.titleLabel.text = "Error getting \(source.serviceName) data"
                self.updateAppearance(title: "Link might be formatted incorrectly", color: UIColor.darkGray, enabled: false)
            }
        }
    }

    /// Decides how to convert and process playlist
    ///
    /// - Parameter link: link to playlist
    private func handlePlaylist(link: String) {
        linkTextField.isEnabled = true
        // Ensure user is logged in to Spotify
        handleSpotifyLogin { spotifyToken, error in
            if error == nil {
                // Ensure Apple Music is logged in
                let spotifyPlaylistSearcher = SpotifyPlaylistSearcher(token: spotifyToken)
                let appleMusicPlaylistSearcher = AppleMusicPlaylistSearcher(token: self.appleMusic.token)

                if link.contains("open.spotify.com") {
                    self.convertPlaylist(link: link, source: spotifyPlaylistSearcher, destination: appleMusicPlaylistSearcher)
                } else if link.contains("itunes.apple.com") || link.contains("music.apple.com") {
                    self.convertPlaylist(link: link, source: appleMusicPlaylistSearcher, destination: spotifyPlaylistSearcher)
                } else {
                    self.updateAppearance(title: "I don't recognize that playlist ☹️", color: UIColor.darkGray, enabled: false)
                }
                self.linkTextField.isEnabled = true
            } else {
                self.updateAppearance(title: "I had trouble logging into Spotify ☹️", color: UIColor.darkGray, enabled: false)
                self.linkTextField.isEnabled = true
            }
        }
    }

    /// Ensures that the user is logged into Spotify and the application has permission to modify
    /// private playlists
    ///
    /// - Parameter completion: What to do with login token after login is completed
    private func handleSpotifyLogin(completion: @escaping (String?, Error?) -> Void) {
        SpotifyLogin.shared.getAccessToken { token, error in
            switch error {
            case nil: completion(token, error)
            default: SpotifyLoginPresenter.login(from: self, scopes: [.playlistModifyPrivate])
            }
        }
    }

    /// Adds the playlist
    ///
    /// - Parameters:
    ///   - destination: where to add the playlist
    ///   - trackList: list of tracks [track name: artist name]
    ///   - playlistName: Name of the playlist
    private func addPlaylist(destination: PlaylistSearcher, trackList: [PlaylistTrack], playlistName: String) {
        // Show some cool animations
        addPastelView()
        titleLabel.text = playlistName
        updateAppearance(title: "DON'T CLOSE CONVERTIFY WHILE THIS IS RUNNING! This might take a while.", color: UIColor.darkGray, enabled: false)
        destination.addPlaylist(trackList: trackList, playlistName: playlistName) { _, _, error in
            if error == nil {
                self.updateAppearance(title: "Converted successfully, check your library for the new playlist", color: UIColor.darkGray, enabled: false)
            } else {
                self.updateAppearance(title: "We had problems converting this playlist", color: UIColor.darkGray, enabled: false)
            }
            self.pastelView.removeFromSuperview()
        }
    }

    /// Converts a playlist
    ///
    /// - Parameters:
    ///   - link: link of playlist
    ///   - source: source for the playlist
    ///   - destination: where to add the playlist
    private func convertPlaylist(link: String, source: PlaylistSearcher, destination: PlaylistSearcher) {
        source.getTrackList(link: link) { trackList, playlistName, error in
            if error == nil {
                self.playlistTracks = trackList ?? []

                self.performSegue(withIdentifier: "openPlaylistTracks", sender: nil)

                let alert = UIAlertController(title: "Add \(playlistName ?? "") to \(destination.serviceName)?",
                                              message: "This playlist will be added to your \(destination.serviceName) library with the closest matches we can find.",
                                              preferredStyle: UIAlertController.Style.alert)

                // Yes, add the playlist
//                alert.addAction(UIAlertAction(title: "Yes", style: UIAlertAction.Style.default) { _ in
//                    self.addPlaylist(destination: destination,
//                                     trackList: trackList,
//                                     playlistName: playlistName ?? "New Playlist")
//                })

                // No, do nothing
                alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel) { _ in
                    self.updateAppearance(title: "Not converting playlist", color: UIColor.darkGray, enabled: false)
                })
                // Show the alert
//                self.present(alert, animated: true, completion: nil)

                // Add segue to playlist view

            } else {
                self.updateAppearance(title: "We had problems converting this playlist. Does Convertify have access to your Apple Music library?", color: UIColor.darkGray, enabled: false)
            }
        }
    }

    /// Adds pretty animation for converting playlists
    private func addPastelView() {
        // Custom Direction
        pastelView.startPastelPoint = .left
        pastelView.endPastelPoint = .right
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

    // MARK: Actions

    /// Opens the link in the opposite app
    @IBAction func openSong(_: Any) {
        if link != nil {
            UIApplication.shared.open(URL(string: link!)!, options: [:])
        }
    }

    @IBAction func linkFieldDidChange(_: Any) {
        print(linkTextField.text ?? "NO TEXT ENTERED")
        handleLink(link: linkTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "")
    }

    /// Opens the help pop-up
    @IBAction func openHelp(_: Any) {
        let alert = UIAlertController(title: "How to Convertify",
                                      message: "In Spotify or Apple Music, share a song, artist, album, or playlist and copy the link to it. Paste it in the Convertify magic text box and convert away!",
                                      preferredStyle: UIAlertController.Style.alert)

        // Do nothing
        alert.addAction(UIAlertAction(title: "Cool!", style: UIAlertAction.Style.default) { _ in
            // Do nothing
        })

        // Show the alert
        present(alert, animated: true, completion: nil)
    }

    func continueAfterSpotifyAuth() {
        if !(linkTextField.text?.isEmpty ?? true) {
            handleLink(link: linkTextField.text!)
        }
    }

    /// Dismiss the keyboard, used as a slector
    @objc func dismissKeyboard(_: UITapGestureRecognizer) {
        linkTextField.resignFirstResponder()
    }

    func textFieldShouldReturn(_: UITextField) -> Bool {
        view.endEditing(true)
        return false
    }

    /// Pass the playlist tracks to the new list
    override func prepare(for segue: UIStoryboardSegue, sender _: Any?) {
        if segue.identifier == "openPlaylistTracks" {
            let vc = segue.destination as! PlaylistTableViewController
            vc.tracks = playlistTracks
        }
    }
}
