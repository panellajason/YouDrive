//
//  SearchResultsViewController.swift
//  YouDrive
//
//  Created by Panella, Jason on 10/16/22.
//

import MapKit
import UIKit

class SearchResultsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet weak var buttonClose: UIButton!
    @IBOutlet weak var labelTitle: UILabel!
    @IBOutlet weak var tableViewSearchResults: UITableView!
    
    var searchResults: [MKMapItem]!
    var searchQuery: String!
    var searchDelegate: SearchDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableViewSearchResults.dataSource = self
        tableViewSearchResults.delegate = self
        tableViewSearchResults.backgroundColor = .white
        
        labelTitle.text = "Search results for " + "\"" + searchQuery + "\""
    }
        
    @IBAction func handleCloseAction(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let location: MKMapItem = searchResults[indexPath.row]
        searchDelegate?.onLocationSelected(location: location)
        
        self.dismiss(animated: true, completion: nil)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        searchResults.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 55
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let resultsCell = tableView.dequeueReusableCell(withIdentifier: SearchResultsTableViewCell.identifier,
                                                        for: indexPath) as! SearchResultsTableViewCell
        resultsCell.configure(with: searchResults[indexPath.row])
        return resultsCell
    }
}
