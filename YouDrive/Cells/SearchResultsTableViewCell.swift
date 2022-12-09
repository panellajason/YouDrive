//
//  SearchResultsTableViewCell.swift
//  YouDrive
//
//  Created by Panella, Jason on 10/16/22.
//

import MapKit
import UIKit

// Tableview cell for displaying search results for locations.
class SearchResultsTableViewCell: UITableViewCell {
    
    static let identifier = "SearchResultsTableViewCell"
    
    @IBOutlet weak var labelDescription: UILabel!
    @IBOutlet weak var labelDistance: UILabel!
    @IBOutlet weak var labelTitle: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func configure(with searchResult: MKMapItem, searchType: String, startLocation: CLLocationCoordinate2D?) {
        let distance = SearchService.caclulateDistance(destination: searchResult.placemark.coordinate, startLocation: startLocation  ?? SearchService.currentLocation)
        
        labelDescription.text = searchResult.placemark.title
        if searchType == SearchType.END_LOCATION.rawValue {
            labelDistance.text = distance.description + " mi"
        }
        labelTitle.text = searchResult.name
    }
}
