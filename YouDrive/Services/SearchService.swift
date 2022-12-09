//
//  SearchService.swift
//  YouDrive
//
//  Created by Panella, Jason on 10/17/22.
//

import CoreLocation
import Foundation
import MapKit

class SearchService {
    static var currentLocation : CLLocationCoordinate2D!

    // Calculates distance in miles between two points.
    static func caclulateDistance(destination: CLLocationCoordinate2D, startLocation: CLLocationCoordinate2D) -> Double {
        let currentPoint = CLLocation(latitude: startLocation.latitude, longitude: startLocation.longitude)
        let endPoint = CLLocation(latitude: destination.latitude ,longitude: destination.longitude)
        
        let distanceInMeters = currentPoint.distance(from: endPoint)
        let distanceInMiles = distanceInMeters / 1609.344
        
        return distanceInMiles.rounded(toPlaces: 1)
    }
    
    // Uses Apple's MKLocalSearch api to search for locations by using a query string.
    static func searchForLocations(searchLocation: CLLocationCoordinate2D, searchQuery: String, completion: @escaping(Error?, [MKMapItem]) -> ()) {
        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        let region = MKCoordinateRegion(center: searchLocation, span: span)
        
        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = searchQuery
        searchRequest.region = region
                
        let search = MKLocalSearch(request: searchRequest)
        search.start { response, error in
            guard error == nil else { return completion(error, []) }
            return completion(error, response?.mapItems ?? [])
        }
    }
}

// Delegate for updating AddDriveViewCcontroller after selecting a location in SearchResultsViewController.
protocol SearchDelegate {
    func onLocationSelected(location: MKMapItem, type: String)
}

// Types of lcoation searches.
enum SearchType: String {
    case END_LOCATION
    case STARTING_LOCATION
}
