![Convertify-Logo-Header](https://user-images.githubusercontent.com/20470485/44062049-b0e8792c-9f0f-11e8-81b0-73d65235c958.png)

# Convertify

A new iOS app that open Spotify links in Apple Music and Apple Music links in Spotify like magic!

## How to use

Open Convertify after installing and follow the prompts for logging into Spotify. Spotify login is required for searching Spotify

Simply copy a link to an Apple Music or Spotify album, artist, or song, and open Convertify. It will automatically detect the link and allow you to open it in the opposite app.

## Getting Started

These instructions will get you a copy of the project up and running on your local machine for development and testing purposes. See deployment for notes on how to deploy the project on a live system.

### Prerequisites

- [Cocoapods](https://cocoapods.org)
- [Spotify Account](https://www.spotify.com/) (Premium **not** required, app not required)
- [Apple developer account](https://developer.apple.com)

### Installing

1. `pod install` inside the repository directory
2. Open `Convertify.xcworkspace`
3. Complete `Stores/Auth.swift` with your information from Spotify's developer console and Apple Developer's web console. Remember to use the JWT from Apple Music. I used [this tool](https://github.com/pelauimagineering/apple-music-token-generator)) to get the JWT.

## Running the tests

Test within Xcode using the `ConvertifyTests`. These tests **must** be run on a device or simulator that has logged into Spotify.

## Built With

- [AlamoFire](https://github.com/Alamofire/Alamofire) - For the HTTP requests to both Apple Music and Spotify
- [SpotifyLogin](https://github.com/spotify/SpotifyLogin) - For handling Spotify Authentication and credentials
- [Apple Music Token Generator](https://github.com/pelauimagineering/apple-music-token-generator) - For generating the Apple Music tokens securely

## Authors

- **Hayden Hong** - _Lead developer_ - [Personal website](haydenhong.com)
