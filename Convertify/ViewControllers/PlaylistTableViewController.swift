//
//  PlaylistTableViewController.swift
//  Convertify
//
//  Created by Hayden Hong on 11/4/19.
//  Copyright © 2019 Hayden Hong. All rights reserved.
//

import SDWebImage
import UIKit

class PlaylistTableViewController: UITableViewController {
    // MARK: Properties

    var tracks: [PlaylistTrack] = []
    var playlistTitle: String = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.allowsSelection = false
        navigationItem.title = playlistTitle
    }

    // MARK: - Table view data source

    override func numberOfSections(in _: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        return tracks.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "trackCell"

        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? TrackTableViewCell else {
            fatalError("The dequeued cell is not an instance of TrackTableViewCell.")
        }

        cell.trackNameLabel.text = tracks[indexPath.row].trackName
        cell.artistNameLabel.text = tracks[indexPath.row].artistName
        cell.albumArtImageView.layer.cornerRadius = 3
        // Get album art
        guard let urlString = tracks[indexPath.row].albumArt?
            .replacingOccurrences(of: "{w}", with: "60")
            .replacingOccurrences(of: "{h}", with: "60") else { return cell }

        cell.albumArtImageView.sd_setImage(with: URL(string: urlString))

        return cell
    }

    @IBAction func convertButtonClicked(_: Any) {
        performSegue(withIdentifier: "unwindToMainViewController", sender: nil)
    }
}
