//
//  WidgetService.swift
//  YouDrive
//
//  Created by Panella, Jason on 10/15/22.
//

import UIKit

class WidgetService {
    
    static let ICON_PREFIX = "icon_"
    
    static func getIconIdList() -> [String] {
        
        var iconIdList: [String] = []
        
        for index in 2...25 {
            iconIdList.append(index.description)
        }
        
        return iconIdList.shuffled()
    }
}

// Loading spinner.
var vSpinner : UIView?
extension UIViewController {
    
    // Show spinner over view controller
    func showSpinner(onView : UIView) {
        let spinnerView = UIView.init(frame: onView.bounds)
        spinnerView.backgroundColor = UIColor.init(red: 0.5, green: 0.5, blue: 0.5, alpha: 0.5)
        let ai = UIActivityIndicatorView.init(style: .large)
        ai.startAnimating()
        ai.center = spinnerView.center
        DispatchQueue.main.async {
            spinnerView.addSubview(ai)
            onView.addSubview(spinnerView)
        }
        vSpinner = spinnerView
    }
    
    // Remove spinner from view controller
    func removeSpinner() {
        DispatchQueue.main.async {
            vSpinner?.removeFromSuperview()
            vSpinner = nil
        }
    }
}

// Rounds Double to decimal places value.
extension Double {
    func rounded(toPlaces places:Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}
