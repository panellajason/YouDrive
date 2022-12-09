//
//  SearchResultsViewController.swift
//  YouDrive
//
//  Created by Panella, Jason on 10/16/22.
//

import MapKit
import UIKit

class SearchResultsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var searchDelegate: SearchDelegate?
    var searchResults: [MKMapItem] = []
    var searchQuery: String!
    var searchType: String!
    var startLocation: CLLocationCoordinate2D!
    
    @IBOutlet weak var buttonClose: UIButton!
    @IBOutlet weak var labelTitle: UILabel!
    @IBOutlet weak var tableViewSearchResults: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableViewSearchResults.dataSource = self
        tableViewSearchResults.delegate = self
        
        labelTitle.text = "Search results for " + "\"" + searchQuery + "\""
    }
        
    // Handles on-click for the "X" button.
    @IBAction func handleCloseAction(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let location: MKMapItem = searchResults[indexPath.row]
        searchDelegate?.onLocationSelected(location: location, type: searchType)
        
        self.dismiss(animated: true, completion: nil)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        searchResults.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 65
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let resultsCell = tableView.dequeueReusableCell(withIdentifier: SearchResultsTableViewCell.identifier,
                                                        for: indexPath) as! SearchResultsTableViewCell
        resultsCell.configure(with: searchResults[indexPath.row], searchType: searchType, startLocation: startLocation)
        return resultsCell
    }
}
