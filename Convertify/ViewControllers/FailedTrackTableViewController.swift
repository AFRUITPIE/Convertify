//
//  FailedTrackTableViewController.swift
//  Convertify
//
//  Created by Hayden Hong on 2/19/19.
//  Copyright © 2019 Hayden Hong. All rights reserved.
//

import Foundation
import UIKit

class FailedTrackTableViewController: UITableViewController {
    var failedTracks: [String] = []
    let cellReuseIdentifier = "cell"

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        return failedTracks.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // create a new cell if needed or reuse an old one
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) // set the text from the data model
        cell.textLabel?.text = failedTracks[indexPath.row]

        return cell
    }
}
