//
//  ViewController.swift
//  Convertify
//
//  Created by Hayden Hong on 8/7/18.
//  Copyright © 2018 Hayden Hong. All rights reserved.
//

import Alamofire
import SpotifyLogin
import UIKit

class ViewController: UIViewController {
    private var spotifyToken: String?
    var link: String?
    
    // Mark: Properties
    @IBOutlet var convertButton: UIButton!
    @IBOutlet var titleLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
        
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Initialize with this color for animations' sake

        NotificationCenter.default.addObserver(self, selector: #selector(setupSpotifyCredentials), name: .SpotifyLoginSuccessful, object: nil)
        setupSpotifyCredentials()
    }
    
    @objc func changeButtonAppearance() {
        if (self.link!.contains("https://open.spotify.com/")) {
            setConvertButton(title: "Open in Apple Music", color: UIColor(red:0.98, green:0.34, blue:0.76, alpha:1.0), enabled: true)
            convertButton.isEnabled = true;
        } else if (self.link!.contains("https://itunes.apple.com/")) {
            setConvertButton(title: "Open in Spotify", color: UIColor(red:0.52, green:0.74, blue:0.00, alpha:1.0), enabled: true)
        } else {
            setConvertButton(title: "No link found in clipboard", color: UIColor.gray, enabled: false)
        }
    }
    
    private func setConvertButton(title: String, color: UIColor, enabled: Bool) {
        convertButton.setTitle(title, for: .normal)
        
        // Animate color shift
        UIView.animate(withDuration: 3.0, delay: 0.0, animations: {
            self.titleLabel.textColor = UIColor.white
            self.view.backgroundColor = color
            self.convertButton.setTitleColor(UIColor.white, for: .normal)
        }, completion:nil)
        
        
        convertButton.isEnabled = enabled;
    }
    
    @objc func setupSpotifyCredentials() {
        SpotifyLogin.shared.getAccessToken { (accessToken, error) in
            if (accessToken != nil) {
                self.spotifyToken = accessToken
            } else {
                // Alert users to needing Spotify login
                let alert = UIAlertController(title: "Spotify Login Not Found", message: "This app requires a Spotify account. Please login now.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: NSLocalizedString("Login", comment: "Open Spotify Login"), style: .default, handler: { _ in
                    // Open the Spotify login prompt
                    SpotifyLoginPresenter.login(from: self, scopes: [])
                }))
                self.present(alert, animated: true, completion: nil)
            }
            
            if (error != nil) {
                print (error ?? "")
            }
        }
    }
    
    @objc func finishLogin() {
        SpotifyLogin.shared.getAccessToken { (accessToken, error) in
            if (accessToken != nil) {
                self.spotifyToken = accessToken
            } else {
                // Logout just in case
                SpotifyLogin.shared.logout()
                let alert = UIAlertController(title: "We had trouble logging in", message: "Please try logging into Spotify again", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: NSLocalizedString("Retry", comment: "Retry Spotify login"), style: .default, handler: { _ in
                    // restart Spotify login flow
                    self.setupSpotifyCredentials()
                }))
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    // Mark: Actions
    @IBAction func convertLink(_ sender: Any) {
        if (self.link!.contains("https://open.spotify.com/")) {
            // Get the Apple Music version if the link is Spotify
            if (spotifyToken != nil) {
                openInAppleMusic(link: self.link!, token: spotifyToken!)
            } else {
                setupSpotifyCredentials()
            }
        } else if (self.link!.contains("https://itunes.apple.com/")) {
            // Get the Spotify version if the link is Apple Music
            // searchAppleMusic(link: self.link!)
        } else {
            // Open an alert if the link is incorrectly formatted
            
            let alert = UIAlertController(title: "Incorrect Link", message: "This link is not formatted correctly: \(self.link ?? "")", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Close error"), style: .default, handler: { _ in
            }))
            present(alert, animated: true, completion: nil)
        }
    }
}
