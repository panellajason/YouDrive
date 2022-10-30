//
//  AddDriveViewController.swift
//  YouDrive
//
//  Created by Panella, Jason on 10/16/22.
//

import CoreLocation
import DropDown
import MapKit
import UIKit

class AddDriveViewController: UIViewController, CLLocationManagerDelegate, SearchDelegate {
    // Dropdown to select a group to show.
    private let groupsDropdown: DropDown = DropDown()

    let locationManager = CLLocationManager()
    
    var addDriveDelegate: AddDriveDelegate?
    var searchResults: [MKMapItem]!
    var selectedLocation: String?
    var selectedLocationDistance: String?
        
    @IBOutlet weak var buttonGroupEdit: UIButton!
    @IBOutlet weak var buttonSearch: UIButton!
    @IBOutlet weak var buttonSubmit: UIButton!
    @IBOutlet weak var buttonRefresh: UIBarButtonItem!
    @IBOutlet weak var dropdownAnchor: UILabel!
    @IBOutlet weak var labelError: UILabel!
    @IBOutlet weak var labelGroup: UILabel!
    @IBOutlet weak var labelSearch: UILabel!
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

    override func viewDidLoad() {
        super.viewDidLoad()
        
        textfieldPassengers.addTarget(self, action: #selector(updatePointsLabel(textField:)), for: .editingChanged)

        let labelGroupOnClick = UITapGestureRecognizer(target: self, action: #selector(AddDriveViewController.editGroup))
        labelGroup.isUserInteractionEnabled = true
        labelGroup.addGestureRecognizer(labelGroupOnClick)
        
        guard let homeGroup = UserDatabaseService.currentUserProfile?.homeGroup else { return }
        labelGroup.text = homeGroup
        
        setupLocationManager()
        setupDropdown()
    }
    
    // Handles on-click for the submit button.
    @IBAction func handleSubmitButton(_ sender: Any) {
        self.view.endEditing(true)

        guard selectedLocation != nil else {
            labelError.textColor = .red
            labelError.text = "No location selected."
            return
        }
        
        guard textfieldPassengers.text != "" else {
            labelError.textColor = .red
            labelError.text = "Enter number of passengers."
            return
        }
        
        addDrive()
    }
    
    // Handles on-click for the edit gorup button.
    @IBAction func handleGroupEditButton(_ sender: Any) {
        editGroup()
    }
    
    // Handles on-click for the "X" button.
    @IBAction func handleCloseAction(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    // Handles on-click for the refresh button.
    @IBAction func handleRefreshButton(_ sender: Any) {
        refresh()
    }
    
    // Handles on-click for the search button.
    @IBAction func handleSearchButton(_ sender: Any) {
        self.view.endEditing(true)

        guard textfieldSearch.text != "" else {
            labelSearch.text = "Enter a location."
            return
        }
        
        guard SearchService.currentLocation != nil else {
            labelSearch.text = "Cannot determine your location."
            locationManager.requestWhenInUseAuthorization()
            return
        }
        
        search()
    }
    
    // Uses DriveDatabaseService to add a new drive.
    func addDrive() {
        
        guard let distance = selectedLocationDistance?.description else { return }
        guard let groupName = labelGroup.text else { return }
        guard let location = selectedLocation else { return }
        guard let numOfPassengers = textfieldPassengers.text else { return }
        
        guard let currentUser = UserDatabaseService.currentUserProfile else { return }

        let oldPoints = 0.0
        
        let newPoints = (Double(numOfPassengers) ?? 0.0) * (Double(distance) ?? 0.0)

        let driveToAdd = Drive(distance: distance, groupName: groupName, location: location, newPoints: newPoints.rounded(toPlaces: 1).description, numberOfPassengers: numOfPassengers, oldPoints: oldPoints.description, userId: currentUser.userId, username: currentUser.username)
        
        DriveDatabaseService.addDriveToGroup(driveToAdd: driveToAdd){ [weak self] error in
            
            guard error == nil else {
                self?.removeSpinner()
                self?.labelError.textColor = .red
                self?.labelError.text = "Unable to add drive, try again."
                return
            }
            
            self?.addDriveDelegate?.onDriveAdded()
            self?.dismiss(animated: true, completion: nil)
        }
    }
    
    // Shows dropdown for user to select a group.
    @objc func editGroup() {
        self.view.endEditing(true)

        groupsDropdown.show()
    }
    
    // Resets all labels and textviews.
    func refresh() {
        self.view.endEditing(true)
        
        labelError.textColor = .red
        labelError.text = ""
        labelSearch.text = ""
        textfieldPassengers.text = ""
        textfieldSearch.text = ""
        selectedLocation = nil
        selectedLocationDistance = ""
        
        guard let homeGroup = UserDatabaseService.currentUserProfile?.homeGroup else { return }
        labelGroup.text = "Group: " + homeGroup
        groupsDropdown.clearSelection()
    }
    
    // Sets up dropdown which displays all the groups that the current user is in.
    func setupDropdown() {
        
        groupsDropdown.anchorView = dropdownAnchor
        groupsDropdown.dataSource = UserDatabaseService.groupsForCurrentUser
        
        groupsDropdown.selectionAction = { [weak self] index, title in
            self?.labelGroup.text = "Group: " + title
        }
    }
    
    // Uses SearchService to search for locations based on search query.
    func search() {
        self.showSpinner(onView: self.view)

        SearchService.searchForLocations(searchQuery: textfieldSearch.text ?? "") {[weak self] error, mapItems in
            
            guard error == nil && !mapItems.isEmpty else {
                self?.removeSpinner()
                self?.labelError.textColor = .red

                switch error?._code ?? Int(MKError.unknown.rawValue) {
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
    
    // Sets up location manager.
    func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        
        startUpdatingLocationIfAllowed(status: locationManager.authorizationStatus)
    }
    
    // Starts updating location if allowed from user.
    func startUpdatingLocationIfAllowed(status: CLAuthorizationStatus) {
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
            case CLAuthorizationStatus.notDetermined:
                self.locationManager.startUpdatingLocation()
                break
            default:
                print("Location tracking denied from user.")
        }
    }
    
    // Updates distance label when user selects location in SearchResultsViewController.
    func onLocationSelected(location: MKMapItem) {
        selectedLocation = location.name?.description
        selectedLocationDistance = SearchService.caclulateDistance(destination: location.placemark.coordinate).description
        labelSearch.text = "Distance: " + (selectedLocationDistance ?? "") + " miles"
        
        guard let numOfPassengers = textfieldPassengers.text else { return }

        if numOfPassengers.count > 0 {
            calculatePoints()
        }
    }
    
    // Updates currentLocation when location changes.
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location: CLLocationCoordinate2D = manager.location?.coordinate else { return }
        SearchService.currentLocation = location
    }
    
    // Checks if location tracking is allowed when authorization status changes.
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        startUpdatingLocationIfAllowed(status: status)
    }
    
    // Listens for textfieldPassengers updates.
    @objc final private func updatePointsLabel(textField: UITextField) {
        
        guard selectedLocation != nil else {
            return
        }
        
        guard textField.text?.count != 0 else {
            labelError.text = ""
            return
        }
                
        calculatePoints()
    }
    
    // Calculates number of points from drive.
    func calculatePoints() {
        guard let numOfPassengers = Double(textfieldPassengers.text ?? "") else { return }
        guard let distance = Double(selectedLocationDistance ?? "") else { return }
        let points = numOfPassengers * distance
        
        labelError.textColor = .black
        labelError.text = "Points: " + String(points.rounded(toPlaces: 1))
    }
    
    // Hides keyboard when user taps screen.
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
       self.view.endEditing(true)
    }
    
    // Sets up SearchResultsViewController before segue.
    override func prepare(for segue: UIStoryboardSegue, sender: Any?){
        if segue.identifier == SegueType.toSearchResults.rawValue {
            let searchResultsViewController = segue.destination as! SearchResultsViewController
            searchResultsViewController.searchResults = searchResults
            searchResultsViewController.searchQuery = textfieldSearch.text
            searchResultsViewController.searchDelegate = self
        }
    }
}
