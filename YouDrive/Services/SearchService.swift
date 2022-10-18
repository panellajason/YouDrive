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

    // Calculates distance in miles between two points
    static func caclulateDistance(destination: CLLocationCoordinate2D) -> Double {
        
        let currentPoint = CLLocation(latitude: currentLocation.latitude, longitude: currentLocation.longitude)
        let endPoint = CLLocation(latitude: destination.latitude ,longitude: destination.longitude)
        
        let distanceInMeters = currentPoint.distance(from: endPoint)
        let distanceInMiles = distanceInMeters / 1609.344
        
        return distanceInMiles.rounded(toPlaces: 1)
    }
    
    // Uses Apple's MKLocalSearch api to search for locations
    static func searchForLocations(searchQuery: String, completion: @escaping(Error?, [MKMapItem]) -> ()) {
        
        guard !searchQuery.isEmpty else {
            return
        }
        
        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        let region = MKCoordinateRegion(center: SearchService.currentLocation, span: span)
        
        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = searchQuery
        searchRequest.region = region
                
        let search = MKLocalSearch(request: searchRequest)

        search.start { response, error in
            guard error == nil else {
                completion(error, [])
                return
            }
            
            completion(error, response?.mapItems ?? [])
        }
    }
}

// Rounds Double to decimal places value
extension Double {
    func rounded(toPlaces places:Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}

protocol SearchDelegate {
    func onLocationSelected(location: MKMapItem)
}
