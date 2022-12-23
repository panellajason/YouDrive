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
    
    private var shouldEndSearch = false
    private var shouldStartSearch = false
    private var useCurrentLocation = true

    let locationManager = CLLocationManager()

    var addDriveDelegate: AddDriveDelegate?
    var searchQuery: String!
    var searchResults: [MKMapItem]!
    var searchType: String!
    var selectedEndCoordinate: CLLocationCoordinate2D?
    var selectedEndLocation: String?
    var selectedStartCoordinate: CLLocationCoordinate2D?
    var selectedStartLocation: String?
    var selectedEndLocationDistance: Double?
    var userObjectsInGroup: [UserGroup] = []
    var usersInGroup: [String] = []

    @IBOutlet weak var dropdownAnchor2: UILabel!
    @IBOutlet weak var dropdownAnchor: UILabel!
    @IBOutlet weak var labelDriver: UILabel!
    @IBOutlet weak var labelError: UILabel!
    @IBOutlet weak var labelGroup: UILabel!
    @IBOutlet weak var labelEndSearch: UILabel!
    @IBOutlet weak var labelStartingSearch: UILabel!
    @IBOutlet weak var segmentedControlLocation: UISegmentedControl!
    @IBOutlet weak var stackviewStartLocation: UIStackView!
    @IBOutlet weak var textfieldPassengers: UITextField! {
        didSet {
            let placeholderText = NSAttributedString(string: "Enter # of people in car",
                                                        attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
            textfieldPassengers.attributedPlaceholder = placeholderText
            textfieldPassengers.keyboardType = .numberPad
        }
    }
    @IBOutlet weak var textfieldEndSearch: UITextField! {
        didSet {
            let placeholderText = NSAttributedString(string: "Destination",
                                                        attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
            textfieldEndSearch.attributedPlaceholder = placeholderText
        }
    }
    @IBOutlet weak var textfieldStartSearch: UITextField! {
        didSet {
            let placeholderText = NSAttributedString(string: "Starting location",
                                                        attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
            textfieldStartSearch.attributedPlaceholder = placeholderText
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupDriverDropdown()
        setupGroupDropdown()
        setupLocationManager()
        setupUI()
    }
    
    // Handles on-click for the segmented control.
    @IBAction func didChangeSegmentedControl(_ sender: UISegmentedControl) {
        refreshLocations()
        
        if sender.selectedSegmentIndex == 0 {
            useCurrentLocation = true
            stackviewStartLocation.isHidden = true
        } else {
            useCurrentLocation = false
            stackviewStartLocation.isHidden = false
        }
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
    
    // Handles on-click for the search end location button.
    @IBAction func handleEndSearchButton(_ sender: Any) {
        self.view.endEditing(true)
        
        guard textfieldEndSearch.text != "" else {
            labelEndSearch.text = "Enter a location."
            return
        }
        
        guard SearchService.currentLocation != nil else {
            labelEndSearch.text = "Cannot determine your location."
            locationManager.requestWhenInUseAuthorization()
            shouldEndSearch = true
            return
        }
        
        executeEndLocationSearch()
    }
    
    // Handles on-click for the search start location button.
    @IBAction func handleStartSearchButton(_ sender: Any) {
        self.view.endEditing(true)
        
        guard textfieldStartSearch.text != "" else {
            labelStartingSearch.text = "Enter a location."
            return
        }
        
        guard SearchService.currentLocation != nil else {
            labelStartingSearch.text = "Cannot determine your location."
            locationManager.requestWhenInUseAuthorization()
            shouldStartSearch = true
            return
        }
        
        executeStartLocationSearch()
    }
    
    // Handles on-click for the submit button.
    @IBAction func handleSubmitButton(_ sender: Any) {
        self.view.endEditing(true)
        labelError.textColor = .red

        if !useCurrentLocation {
            guard selectedStartCoordinate != nil else {
                labelError.text = "No starting location selected."
                return
            }
        }
        
        guard selectedEndCoordinate != nil else {
            labelError.text = "No destination selected."
            return
        }
        
        guard let numOfPassengers = textfieldPassengers.text else { return }
        guard !numOfPassengers.isEmpty else {
            labelError.text = "Enter number of people in car."
            return
        }
        
        guard let passengersDouble = Double(numOfPassengers) else { return }
        guard passengersDouble > 1 else {
            labelError.text = "Must be 2 or more people in car."
            return
        }
        
        guard passengersDouble < 9 else {
            labelError.text = "Enter a reasonable amount of people in car."
            return
        }
        
        labelError.textColor = .black
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
        guard selectedEndLocationDistance != nil else { return }
        guard textField.text?.count != 0 else {
            labelError.text = ""
            return
        }
        calculatePoints()
    }
    
    // Uses DriveDatabaseService to add a new drive.
    private func addDrive() {
        guard let user = userObjectsInGroup.first(where: {$0.username == labelDriver.text}) else { return }
        guard let distance = selectedEndLocationDistance else { return }
        guard let groupName = labelGroup.text else { return }
        guard let location = selectedEndLocation else { return }
        guard let numOfPassengers = textfieldPassengers.text else { return }
        guard let passengersDouble = Double(numOfPassengers) else { return }
        guard let peopleInCar = Int(numOfPassengers) else { return }
        let pointsEarned = (distance * passengersDouble) * 2.0
        
        let driveToAdd = Drive(distance: distance, groupName: groupName, location: location, peopleInCar: peopleInCar, pointsEarned: pointsEarned.rounded(toPlaces: 1), timestamp: Date().timeIntervalSince1970.description, user: user)
        DriveDatabaseService.addDriveToGroup(driveToAdd: driveToAdd){ [weak self] error in
            self?.removeSpinner()

            guard error == nil else {
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
        if !useCurrentLocation && (selectedStartCoordinate == nil || selectedEndCoordinate == nil) {
            return
        }
        
        guard let distance = selectedEndLocationDistance else { return }
        guard let passengers = textfieldPassengers.text else { return }
        guard let passengersDouble = Double(passengers) else { return }
        let points = (distance * passengersDouble) * 2.0
        
        labelError.textColor = .black
        labelError.text = "Points earned: " + points.rounded(toPlaces: 1).description
        self.view.endEditing(true)
    }
    
    private func executeEndLocationSearch() {
        guard let query = textfieldEndSearch.text else { return }
        searchQuery = query
        searchType = SearchType.END_LOCATION.rawValue
        guard let searchLocation = getSearchLocation() else {
            if !useCurrentLocation && selectedStartCoordinate == nil {
                labelEndSearch.text = "No starting location selected."
            }
            return
        }
        search(searchLocation: searchLocation, searchQuery: searchQuery, label: labelEndSearch, type: SearchType.END_LOCATION.rawValue)
        shouldEndSearch = false
    }
    
    private func executeStartLocationSearch() {
        guard let query = textfieldStartSearch.text else { return }
        searchQuery = query
        searchType = SearchType.STARTING_LOCATION.rawValue
        guard let searchLocation = getSearchLocation() else { return }
        search(searchLocation: searchLocation, searchQuery: searchQuery, label: labelStartingSearch, type: SearchType.STARTING_LOCATION.rawValue)
        shouldStartSearch = false
    }
    
    private func getSearchLocation() -> CLLocationCoordinate2D? {
        if searchType == SearchType.END_LOCATION.rawValue && !useCurrentLocation {
            return selectedStartCoordinate
        }
        return SearchService.currentLocation
    }
    
    private func handleGroupDropdownSelection(index: Int, title: String) {
        guard let currentUser = UserDatabaseService.currentUserProfile else { return }
        guard labelGroup.text != title else { return }
        labelGroup.text = title
        
        GroupDatabaseService.getAllUsersInGroup(groupName: title) {[weak self] error, users in
            guard error == nil && users.count != 0 else { return }
            
            var driversList: [String] = []
            for userGroup in users {
                driversList.append(userGroup.username)
            }
            self?.driversDropdown.dataSource = driversList
            
            if title == currentUser.homeGroup {
                UserDatabaseService.driversForHomeGroup = users
            }

            self?.driversDropdown.selectRow(at: driversList.firstIndex(of: currentUser.username))
            self?.labelDriver.text = currentUser.username
            self?.usersInGroup = driversList
            self?.userObjectsInGroup = users
        }
    }
    
    // Resets all labels and textviews.
    private func refresh() {
        self.view.endEditing(true)
        refreshLocations()
        textfieldPassengers.text = ""
        
        guard let currentUser = UserDatabaseService.currentUserProfile else { return }
        labelGroup.text = currentUser.homeGroup
        groupsDropdown.selectRow(at: UserDatabaseService.groupsForCurrentUser.firstIndex(of: currentUser.homeGroup))

        var driversList: [String] = []
        for userGroup in UserDatabaseService.driversForHomeGroup {
            driversList.append(userGroup.username)
        }
        driversDropdown.dataSource = driversList
        
        driversDropdown.selectRow(at: driversList.firstIndex(of: currentUser.username))
        labelDriver.text = currentUser.username
    }
    
    private func refreshLocations() {
        labelEndSearch.text = ""
        labelError.textColor = .red
        labelError.text = ""
        labelStartingSearch.text = ""
        selectedEndCoordinate = nil
        selectedEndLocation = ""
        selectedEndLocationDistance = 0.0
        selectedStartCoordinate = nil
        selectedStartLocation = ""
        textfieldEndSearch.text = ""
        textfieldStartSearch.text = ""
    }
    
    // Uses SearchService to search for locations based on search query.
    private func search(searchLocation: CLLocationCoordinate2D, searchQuery: String, label: UILabel, type: String) {
        self.showSpinner(onView: self.view)
        label.text = ""

        SearchService.searchForLocations(searchLocation: searchLocation, searchQuery: searchQuery) {[weak self] error, mapItems in
            self?.removeSpinner()
            guard error == nil && !mapItems.isEmpty else {
                self?.labelError.textColor = .red

                switch error?._code ?? Int(MKError.unknown.rawValue) {
                    case Int(MKError.loadingThrottled.rawValue):
                        label.text = "Loading throttled, try again."
                    case Int(MKError.placemarkNotFound.rawValue):
                        label.text = "No locations found."
                    case Int(MKError.serverFailure.rawValue):
                        label.text = "No internet."
                    default:
                        label.text = "Unknown error, try again."
                }
                return
            }
            self?.searchResults = mapItems
            self?.performSegue(withIdentifier: SegueType.toSearchResults.rawValue, sender: self)
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
        
        guard let currentUser = UserDatabaseService.currentUserProfile else { return }
        labelGroup.text = currentUser.homeGroup
        groupsDropdown.selectRow(at: UserDatabaseService.groupsForCurrentUser.firstIndex(of: currentUser.homeGroup))
        
        groupsDropdown.selectionAction = { [weak self] index, title in
            self?.handleGroupDropdownSelection(index: index, title: title)
        }
    }
    
    // Sets up location manager.
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
    }
    
    private func setupUI() {
        let selectedTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        segmentedControlLocation.setTitleTextAttributes(selectedTextAttributes, for: .selected)
        
        textfieldPassengers.addTarget(self, action: #selector(updatePointsLabel(textField:)), for: .editingChanged)

        let labelDriverOnClick = UITapGestureRecognizer(target: self, action: #selector(AddDriveViewController.editDriver))
        labelDriver.isUserInteractionEnabled = true
        labelDriver.addGestureRecognizer(labelDriverOnClick)
        
        let labelGroupOnClick = UITapGestureRecognizer(target: self, action: #selector(AddDriveViewController.editGroup))
        labelGroup.isUserInteractionEnabled = true
        labelGroup.addGestureRecognizer(labelGroupOnClick)
        
        guard let currentUser = UserDatabaseService.currentUserProfile else { return }
        labelGroup.text = currentUser.homeGroup
        labelDriver.text = currentUser.username
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
    
    private func updateEndLocation(location: MKMapItem, type: String) {
        selectedEndLocation = location.name?.description
        selectedEndCoordinate = location.placemark.coordinate
        textfieldEndSearch.text = selectedEndLocation
        
        guard var startLocation: CLLocationCoordinate2D = SearchService.currentLocation else { return }
        if !useCurrentLocation {
            if selectedStartCoordinate != nil {
                startLocation = selectedStartCoordinate ?? startLocation
            } else {
                return
            }
        }
        
        selectedEndLocationDistance = SearchService.caclulateDistance(destination: location.placemark.coordinate, startLocation: startLocation)
        
        guard let distance = selectedEndLocationDistance else { return }
        labelEndSearch.text = "Distance: " + distance.description + " miles"
        
        guard let numOfPassengers = textfieldPassengers.text else { return }
        if numOfPassengers.count > 0 {
            calculatePoints()
        }
    }
    
    private func updateStartLocation(location: MKMapItem, type: String) {
        selectedStartLocation = location.name?.description
        selectedStartCoordinate = location.placemark.coordinate
        textfieldStartSearch.text = selectedStartLocation

        if selectedEndCoordinate != nil {
            selectedEndLocationDistance = SearchService.caclulateDistance(destination: selectedEndCoordinate!, startLocation: location.placemark.coordinate)
            
            guard let distance = selectedEndLocationDistance else { return }
            labelEndSearch.text = "Distance: " + distance.description + " miles"
            
            guard let numOfPassengers = textfieldPassengers.text else { return }
            if numOfPassengers.count > 0 {
                calculatePoints()
            }
        }
    }
    
    // Updates distance label/calculates points when user selects location in SearchResultsViewController.
    func onLocationSelected(location: MKMapItem, type: String) {
        if type == SearchType.END_LOCATION.rawValue {
            updateEndLocation(location: location, type: type)
        } else {
            updateStartLocation(location: location, type: type)
        }
    }
    
    // Updates currentLocation when location changes.
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location: CLLocationCoordinate2D = manager.location?.coordinate else { return }
        SearchService.currentLocation = location
        
        if shouldEndSearch {
            executeEndLocationSearch()
        }
        
        if shouldStartSearch {
            executeStartLocationSearch()
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
            searchResultsViewController.searchQuery = searchQuery
            searchResultsViewController.searchResults = searchResults
            searchResultsViewController.searchType = searchType
            searchResultsViewController.searchDelegate = self
            searchResultsViewController.startLocation = getSearchLocation()
        }
    }
}
