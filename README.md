![Convertify-Logo-Header](https://user-images.githubusercontent.com/20470485/44062049-b0e8792c-9f0f-11e8-81b0-73d65235c958.png)

# Convertify

<a href="https://itunes.apple.com/us/app/convertify-share-music/id1424728187"><img src="https://user-images.githubusercontent.com/20470485/45723747-a3dd1200-bb67-11e8-9eca-eeec88a833ca.png" height="40px"></img></a>

[![Build Status](https://travis-ci.org/AFRUITPIE/Convertify.svg?branch=master)](https://travis-ci.org/AFRUITPIE/Convertify)

A new iOS app that open Spotify links in Apple Music and Apple Music links in Spotify like magic!

## How to use

Simply copy a link to an Apple Music or Spotify album, artist, or song, and open Convertify. It will automatically detect the link and allow you to open it in the opposite app. Cool!

## Getting Started

These instructions will get you a copy of the project up and running on your local machine for development and testing purposes. See deployment for notes on how to deploy the project on a live system.

### Prerequisites

- [Cocoapods](https://cocoapods.org)
- [Spotify Account](https://www.spotify.com/) (Premium **not** required, app not required. Developer console IS required)
- [Apple developer account](https://developer.apple.com)

### Installing

1. `pod install` inside the repository directory
2. Open `Convertify.xcworkspace`
3. Complete `Stores/Auth.swift` with your information from Spotify's developer console and Apple Developer's web console. Remember to use the JWT from Apple Music. I used [this tool](https://github.com/pelauimagineering/apple-music-token-generator)) to get the JWT.

## Running the tests

Test within Xcode. The included tests must be run on a device/simulator of iOS version 11.4 or higher.

## Built With

- [AlamoFire](https://github.com/Alamofire/Alamofire) - For the HTTP requests to both Apple Music and Spotify
- [SDWebImage](https://github.com/SDWebImage/SDWebImage) - For loading of album art in the playlist view
- [SwiftyJSON](https://github.com/SwiftyJSON/SwiftyJSON) - For easier JSON parsing and handling
- [CupertinoJWT](https://github.com/ethanhuang13/CupertinoJWT) - For generating the Apple Music tokens securely

## Authors

- **Hayden Hong** - _Lead developer_ - [Personal website](haydenhong.com)
