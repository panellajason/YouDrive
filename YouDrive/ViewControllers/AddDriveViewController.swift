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
    
    let locationManager = CLLocationManager()
    
    var selectedLocation: String?
    var selectedLocationDistance: String?

    var searchResults: [MKMapItem]!
    
    @IBOutlet weak var buttonRefresh: UIBarButtonItem!
    @IBOutlet weak var buttonSearch: UIButton!
    @IBOutlet weak var buttonSubmit: UIButton!
    @IBOutlet weak var labelSearch: UILabel!
    @IBOutlet weak var textfieldAmount: UITextField! {
        didSet {
            let placeholderText = NSAttributedString(string: "Amount",
                                                        attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
            textfieldAmount.attributedPlaceholder = placeholderText

        }
    }
    @IBOutlet weak var textfieldGroupName: UITextField! {
        didSet {
            let placeholderText = NSAttributedString(string: "Name of group",
                                                        attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
            textfieldGroupName.attributedPlaceholder = placeholderText
        }
    }
    @IBOutlet weak var textfieldPassengers: UITextField! {
        didSet {
            let placeholderText = NSAttributedString(string: "Enter # of passengers",
                                                        attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
            textfieldPassengers.attributedPlaceholder = placeholderText

        }
    }
    @IBOutlet weak var textfieldSearch: UITextField! {
        didSet {
            let placeholderText = NSAttributedString(string: "Enter location",
                                                        attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
            textfieldSearch.attributedPlaceholder = placeholderText
        }
    }
    @IBOutlet weak var textfieldWhoPaid: UITextField! {
        didSet {
            let placeholderText = NSAttributedString(string: "Who paid?",
                                                     attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
            textfieldWhoPaid.attributedPlaceholder = placeholderText
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        requestLocationPermissionIfNeeded()
    }
    
    // Handles on-click for the submit button
    @IBAction func handleSubmitButton(_ sender: Any) {
        self.view.endEditing(true)

        // guard all text is empty, and distance label is not empty
        guard textfieldSearch.text != "" else {
            labelSearch.text = "Enter a location."
            return
        }
        
        self.showSpinner(onView: self.view)

        DatabaseService.addDriveToGroup(
            amount: textfieldAmount.text ?? "",
            distance: selectedLocationDistance?.description ?? "",
            groupName: textfieldGroupName.text ?? "",
            location: selectedLocation ?? "",
            numberOfPassengers: textfieldPassengers.text ?? "",
            whoPaid: textfieldWhoPaid.text ?? ""
        ){ [weak self] error in
            
            guard error == nil else {
                self?.removeSpinner()
                let errorAlert = UIAlertController(title: "Error", message: "Unable to add drive to group.", preferredStyle: .alert)
                errorAlert.addAction(UIAlertAction(title: "Close", style: .cancel, handler: nil))
                self?.present(errorAlert, animated: true)
                return
            }
            
            self?.removeSpinner()
            self?.refresh()
            self?.performSegue(withIdentifier: SegueType.toHome.rawValue, sender: self)
        }
    }
    
    // Handles on-click for the refresh nav item
    @IBAction func handleRefreshButton(_ sender: Any) {
        refresh()
    }
    
    // Handles on-click for the search button
    @IBAction func handleSearchButton(_ sender: Any) {
        self.view.endEditing(true)

        guard textfieldSearch.text != "" else {
            labelSearch.text = "Enter a location."
            return
        }
        
        search()
    }
    
    func refresh() {
        self.view.endEditing(true)
        
        labelSearch.text = ""
        textfieldAmount.text = ""
        textfieldGroupName.text = ""
        textfieldPassengers.text = ""
        textfieldSearch.text = ""
        textfieldWhoPaid.text = ""
    }
    
    // Uses search service to search for locations based on search query
    func search() {
        guard textfieldSearch.text != "" else {
            labelSearch.text = "Enter a location."
            return
        }
        
        labelSearch.text = ""

        self.showSpinner(onView: self.view)

        SearchService.searchForLocations(searchQuery: textfieldSearch.text ?? "") {[weak self] error, mapItems in
            
            guard error == nil && !mapItems.isEmpty else {
                self?.removeSpinner()
                
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
            self?.removeSpinner()
        }
    }
    
    // Requests tracking permission and sets up delegate if granted
    func requestLocationPermissionIfNeeded() {
        locationManager.requestAlwaysAuthorization()
        locationManager.requestWhenInUseAuthorization()
    }
    
    // Updates distance label when user selects location in SearchResultsViewController
    func onLocationSelected(location: MKMapItem) {
        selectedLocation = location.name?.description
        selectedLocationDistance = SearchService.caclulateDistance(destination: location.placemark.coordinate).description
        labelSearch.text = "Distance: " + (selectedLocationDistance ?? "") + " miles"
    }
    
    // Updates currentLocation when location changes
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location: CLLocationCoordinate2D = manager.location?.coordinate else { return }
        SearchService.currentLocation = location
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
            case CLAuthorizationStatus.authorizedAlways:
                self.locationManager.startUpdatingLocation()
                break
            case CLAuthorizationStatus.authorizedWhenInUse:
                self.locationManager.startUpdatingLocation()
                break
            case CLAuthorizationStatus.restricted:
                self.locationManager.startUpdatingLocation()
                break
            default:
                print("Cannot determine location")
        }
    }
    
    // Hides keyboard when user taps screen
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
       self.view.endEditing(true)
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
