//
//  AddDriveViewController.swift
//  YouDrive
//
//  Created by Panella, Jason on 10/16/22.
//

import CoreLocation
import MapKit
import UIKit

class AddDriveViewController: UIViewController, CLLocationManagerDelegate, SearchDelegate {
    @IBOutlet weak var buttonSearch: UIButton!
    @IBOutlet weak var labelSearch: UILabel!
    @IBOutlet weak var textfieldSearch: UITextField! {
        didSet {
            let placeholderText = NSAttributedString(string: "Enter location",
                                                        attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
            textfieldSearch.attributedPlaceholder = placeholderText
        }
    }
    
    let locationManager = CLLocationManager()
    var searchResults: [MKMapItem]!

    override func viewDidLoad() {
        super.viewDidLoad()

        requestLocationPermissionIfNeeded()
    }
    
    // Handle on-click for the search button
    @IBAction func handleSearchButton(_ sender: Any) {
        guard textfieldSearch.text != "" else {
            labelSearch.text = "Enter a location."
            return
        }
        
        search()
    }
    
    // Uses search service to search for locations based on search query
    func search() {
        guard textfieldSearch.text != "" else {
            labelSearch.text = "Enter a location."
            return
        }
        
        labelSearch.text = ""

        SearchService.searchForLocations(searchQuery: textfieldSearch.text ?? "") {[weak self] error, mapItems in
            
            guard error == nil && !mapItems.isEmpty else {
                switch error?._code ?? 1 {
                    case Int(MKError.loadingThrottled.rawValue):
                        self?.labelSearch.text = "Loading throttled, try again."
                    case Int(MKError.placemarkNotFound.rawValue):
                        self?.labelSearch.text = "No locations found."
                    case Int(MKError.serverFailure.rawValue):
                        self?.labelSearch.text = "No internet."
                    default:
                        self?.labelSearch.text = "Unknown error, try again."
                }
                return
            }
            
            self?.searchResults = mapItems
            self?.performSegue(withIdentifier: SegueType.toSearchResults.rawValue, sender: self)
        }
    }
    
    // Requests tracking permission and sets up delegate if granted
    func requestLocationPermissionIfNeeded() {
        locationManager.requestAlwaysAuthorization()
        locationManager.requestWhenInUseAuthorization()

        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
        }
    }
    
    // SearchDelegate function used when user selects location in SearchResultsViewController
    func onLocationSelected(location: MKMapItem) {
        let distance = SearchService.caclulateDistance(destination: location.placemark.coordinate)
        labelSearch.text = distance.description + " miles"
    }
    
    // Update currentLocation when location changes
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location: CLLocationCoordinate2D = manager.location?.coordinate else { return }
        SearchService.currentLocation = location
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?){
        if segue.identifier == SegueType.toSearchResults.rawValue {
            let searchResultsViewController = segue.destination as! SearchResultsViewController
            searchResultsViewController.searchResults = searchResults
            searchResultsViewController.searchQuery = textfieldSearch.text
            searchResultsViewController.searchDelegate = self
        }
    }
}
