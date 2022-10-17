//
//  AddDriveViewController.swift
//  YouDrive
//
//  Created by Panella, Jason on 10/16/22.
//

import CoreLocation
import MapKit
import UIKit

class AddDriveViewController: UIViewController, CLLocationManagerDelegate {
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
    var currentLocation : CLLocationCoordinate2D!;

    override func viewDidLoad() {
        super.viewDidLoad()

        requestLocationPermissionIfNeeded()
    }
    
    // Handle on-click for the search button
    @IBAction func handleAccountAction(_ sender: Any) {
        guard textfieldSearch.text != "" else {
            labelSearch.text = "Enter a location."
            return
        }
        
        search()
    }
    
    // Excecutes a MKLocalSearch request with text from textfield
    func search() {
        let span = MKCoordinateSpan(latitudeDelta: 0.00005, longitudeDelta: 0.00005)
        let region = MKCoordinateRegion(center: currentLocation, span: span)
        
        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = textfieldSearch.text
        searchRequest.region = region
                
        let search = MKLocalSearch(request: searchRequest)

        search.start {[weak self] response, error in
            guard let response = response else {
                
                switch error!._code {
                case Int(MKError.placemarkNotFound.rawValue):
                    self?.labelSearch.text = "No locations found."
                case Int(MKError.serverFailure.rawValue):
                    self?.labelSearch.text = "No internet."
                default:
                    self?.labelSearch.text = "Error: \(error?.localizedDescription ?? "Unknown error")."
                }
                
                return
            }
            
            // Selecting first result for testing
            let selectedDestintation = response.mapItems[0].placemark.location?.coordinate
            
            let currentPoint = CLLocation(latitude: (self?.currentLocation.latitude)!, longitude: (self?.currentLocation.longitude)!)
            let endPoint = CLLocation(latitude: selectedDestintation!.latitude ,longitude: selectedDestintation!.longitude)
            let distance = currentPoint.distance(from: endPoint) / 1609.344

            self?.labelSearch.text = "Distance: \(String(distance.rounded(toPlaces: 1))) miles"
        }
    }
    
    // Requests tracking permission and sets up delegate if granted
    func requestLocationPermissionIfNeeded() {
        self.locationManager.requestAlwaysAuthorization()
        self.locationManager.requestWhenInUseAuthorization()

        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
        }
    }
    
    // Update currentLocation when location changes
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location: CLLocationCoordinate2D = manager.location?.coordinate else { return }
        currentLocation = location
    }
}

extension Double {
    // Rounds the double to decimal places value
    func rounded(toPlaces places:Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}
