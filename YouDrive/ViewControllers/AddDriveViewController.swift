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
    // Dropdown to select a user.
    private let driversDropdown: DropDown = DropDown()
    // Dropdown to select a group to show.
    private let groupsDropdown: DropDown = DropDown()

    let locationManager = CLLocationManager()
    
    private var shouldSearch = false
    
    var addDriveDelegate: AddDriveDelegate?
    var searchResults: [MKMapItem]!
    var selectedLocation: String?
    var selectedLocationDistance: Double?
    var userObjectsInGroup: [UserGroup] = []
    var usersInGroup: [String] = []

    @IBOutlet weak var dropdownAnchor2: UILabel!
    @IBOutlet weak var dropdownAnchor: UILabel!
    @IBOutlet weak var labelDriver: UILabel!
    @IBOutlet weak var labelError: UILabel!
    @IBOutlet weak var labelGroup: UILabel!
    @IBOutlet weak var labelSearch: UILabel!
    @IBOutlet weak var textfieldPassengers: UITextField! {
        didSet {
            let placeholderText = NSAttributedString(string: "Enter # of people in car",
                                                        attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
            textfieldPassengers.attributedPlaceholder = placeholderText
            textfieldPassengers.keyboardType = .numberPad
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

        let labelDriverOnClick = UITapGestureRecognizer(target: self, action: #selector(AddDriveViewController.editDriver))
        labelDriver.isUserInteractionEnabled = true
        labelDriver.addGestureRecognizer(labelDriverOnClick)
        
        let labelGroupOnClick = UITapGestureRecognizer(target: self, action: #selector(AddDriveViewController.editGroup))
        labelGroup.isUserInteractionEnabled = true
        labelGroup.addGestureRecognizer(labelGroupOnClick)
        
        guard let homeGroup = UserDatabaseService.currentUserProfile?.homeGroup else { return }
        labelGroup.text = homeGroup
        
        labelDriver.text = UserDatabaseService.driversForHomeGroup[0].username

        setupLocationManager()
        setupDriverDropdown()
        setupGroupDropdown()
    }
    
    // Handles on-click for the "X" button.
    @IBAction func handleCloseAction(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    // Handles on-click for the edit driver button.
    @IBAction func handleDriverEditButton(_ sender: Any) {
        editDriver()
    }
    
    // Handles on-click for the edit group button.
    @IBAction func handleGroupEditButton(_ sender: Any) {
        editGroup()
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
            shouldSearch = true
            return
        }
        
        search()
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
    
    // Shows drivers dropdown.
    @objc private func editDriver() {
        self.view.endEditing(true)
        driversDropdown.show()
    }
    
    // Shows groups dropdown.
    @objc private func editGroup() {
        self.view.endEditing(true)
        groupsDropdown.show()
    }
    
    // Listens for textfieldPassengers updates to calculate points.
    @objc private func updatePointsLabel(textField: UITextField) {
        guard selectedLocation != nil else { return }
        guard textField.text?.count != 0 else {
            labelError.text = ""
            return
        }
        
        calculatePoints()
    }
    
    // Uses DriveDatabaseService to add a new drive.
    private func addDrive() {
        guard let user = userObjectsInGroup.first(where: {$0.username == labelDriver.text}) else { return }
        guard let distance = selectedLocationDistance else { return }
        guard let groupName = labelGroup.text else { return }
        guard let location = selectedLocation else { return }
        guard let numOfPassengers = textfieldPassengers.text else { return }
        guard let passengersDouble = Double(numOfPassengers) else { return }
        guard let peopleInCar = Int(numOfPassengers) else { return }
        let pointsEarned = (distance * passengersDouble) * 2.0
        
        let driveToAdd = Drive(distance: distance, groupName: groupName, location: location, peopleInCar: peopleInCar, pointsEarned: pointsEarned.rounded(toPlaces: 1), timestamp: Date().timeIntervalSince1970.description, user: user)
        DriveDatabaseService.addDriveToGroup(driveToAdd: driveToAdd){ [weak self] error in
            guard error == nil else {
                self?.removeSpinner()
                self?.labelError.textColor = .red
                self?.labelError.text = "Unable to add drive, try again."
                return
            }
            
            ActivityFeedViewController.eventUpdatesDelegate?.onEventUpdates()
            self?.addDriveDelegate?.onDriveAdded(groupName: groupName)
            self?.dismiss(animated: true, completion: nil)
        }
    }
    
    // Calculates number of points from drive.
    private func calculatePoints() {
        guard let distance = selectedLocationDistance else { return }
        guard let passengers = textfieldPassengers.text else { return }
        guard let passengersDouble = Double(passengers) else { return }
        let points = (distance * passengersDouble) * 2.0
        
        labelError.textColor = .black
        labelError.text = "Points earned: " + points.rounded(toPlaces: 1).description
    }
    
    // Resets all labels and textviews.
    private func refresh() {
        self.view.endEditing(true)
        labelError.textColor = .red
        labelError.text = ""
        labelSearch.text = ""
        textfieldPassengers.text = ""
        textfieldSearch.text = ""
        selectedLocation = nil
        selectedLocationDistance = 0.0
        
        guard let homeGroup = UserDatabaseService.currentUserProfile?.homeGroup else { return }
        labelGroup.text = homeGroup
        groupsDropdown.clearSelection()
        
        var driversList: [String] = []
        for userGroup in UserDatabaseService.driversForHomeGroup {
            driversList.append(userGroup.username)
        }
        driversDropdown.dataSource = driversList
        
        guard let currentUser = UserDatabaseService.currentUserProfile else { return }
        driversDropdown.selectRow(at: driversList.firstIndex(of: currentUser.username))
        labelDriver.text = currentUser.username
    }
    
    // Uses SearchService to search for locations based on search query.
    private func search() {
        self.showSpinner(onView: self.view)
        guard let searchQuery = textfieldSearch.text else { return }

        SearchService.searchForLocations(searchQuery: searchQuery) {[weak self] error, mapItems in
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
    
    // Sets up dropdown which displays all the drivers in selected group.
    private func setupDriverDropdown() {
        driversDropdown.anchorView = dropdownAnchor2
        
        var driversList: [String] = []
        for userGroup in UserDatabaseService.driversForHomeGroup {
            driversList.append(userGroup.username)
        }
        driversDropdown.dataSource = driversList
        usersInGroup = driversList
        userObjectsInGroup = UserDatabaseService.driversForHomeGroup
        
        guard let currentUser = UserDatabaseService.currentUserProfile else { return }
        driversDropdown.selectRow(at: driversList.firstIndex(of: currentUser.username))
        labelDriver.text = currentUser.username
        
        driversDropdown.selectionAction = { [weak self] index, title in
            self?.labelDriver.text = title
        }
    }
    
    // Sets up dropdown which displays all the groups that the current user is in.
    private func setupGroupDropdown() {
        groupsDropdown.anchorView = dropdownAnchor
        groupsDropdown.dataSource = UserDatabaseService.groupsForCurrentUser
        
        groupsDropdown.selectionAction = { [weak self] index, title in
            guard self?.labelGroup.text != title else { return }
            
            self?.labelGroup.text = title
            
            GroupDatabaseService.getAllUsersInGroup(groupName: title) {[weak self] error, users in
                guard error == nil && users.count != 0 else { return }
                
                var driversList: [String] = []
                for userGroup in users {
                    driversList.append(userGroup.username)
                }
                self?.driversDropdown.dataSource = driversList
                
                UserDatabaseService.driversForHomeGroup = users

                self?.labelDriver.text = driversList[0]
                self?.usersInGroup = driversList
                self?.userObjectsInGroup = users
            }
        }
    }
    
    // Sets up location manager.
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
    }
    
    // Starts updating location if allowed from user.
    private func startUpdatingLocationIfAllowed(status: CLAuthorizationStatus) {
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
    
    // Updates distance label/calculates points when user selects location in SearchResultsViewController.
    func onLocationSelected(location: MKMapItem) {
        selectedLocation = location.name?.description
        textfieldSearch.text = selectedLocation
        selectedLocationDistance = SearchService.caclulateDistance(destination: location.placemark.coordinate)
        
        guard let distance = selectedLocationDistance else { return }
        labelSearch.text = "Distance: " + distance.description + " miles"
        
        guard let numOfPassengers = textfieldPassengers.text else { return }
        if numOfPassengers.count > 0 {
            calculatePoints()
        }
    }
    
    // Updates currentLocation when location changes.
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location: CLLocationCoordinate2D = manager.location?.coordinate else { return }
        SearchService.currentLocation = location
        
        if shouldSearch {
            search()
            labelSearch.text = ""
            shouldSearch = false
        }
    }
    
    // Checks if location tracking is allowed when authorization status changes.
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        startUpdatingLocationIfAllowed(status: status)
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
