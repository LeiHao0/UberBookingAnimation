//
//  ViewController.swift
//  UberBookingAnimation
//
//  Created by art on 9/26/19.
//  Copyright © 2019 art. All rights reserved.
//

import UIKit

import MapKit


let center = CLLocationCoordinate2D(latitude: 1.2806521, longitude: 103.848609)
let m1 = CLLocationCoordinate2D(latitude: 1.277619, longitude: 103.852169)
let m2 = CLLocationCoordinate2D(latitude: 1.296770, longitude: 103.851010)
let m3 = CLLocationCoordinate2D(latitude: 1.265631, longitude: 103.822344)

let fromDistance: CLLocationDistance = 6000
let pitch: CGFloat = 60
let heading: CLLocationDirection = 180

class MainViewController: UIViewController {
    
    let mkCamera = MKMapCamera(lookingAtCenter: center, fromDistance: 1000, pitch: 0, heading: 0)
    
    let circleLayer = CAShapeLayer()
    let pinLayer = CAShapeLayer()
    
    private var drawingTimer: Timer?
    var routes = [MKRoute(), MKRoute(), MKRoute()]
    
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var maskView: UIView!
    
    @IBOutlet weak var circleView: UIView!
    @IBOutlet weak var pinView: UIView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.setCamera(mkCamera, animated: false)
        
        searchRoute()
    }
    
    
    @IBAction func rotate(_ sender: UIButton) {
        
        UIView.animate(withDuration: 1) {
            self.maskView.isHidden = false
//            self.maskView.alpha = 0.6
        }
        
        UIView.animate(withDuration: 1, delay: 0, options: .curveEaseInOut, animations: {
            self.mapView.setCamera(MKMapCamera(lookingAtCenter: center, fromDistance: fromDistance, pitch: pitch, heading: 0), animated: true)
        }) { b in
            self.pinAnimation()
            UIView.animate(withDuration: 180, delay: 0, options: [.curveLinear, .autoreverse], animations: {
                self.mapView.setCamera(MKMapCamera(lookingAtCenter: center, fromDistance: fromDistance, pitch: pitch, heading: heading), animated: true)
            }, completion: nil)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.showRoute()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            self.showRoute(true)
        }
        
    }
    
    
    @IBAction func resetAction(_ sender: UIButton) {
        
        UIView.animate(withDuration: 1, animations: {
            self.mapView.setCamera(self.mkCamera, animated: true)
            self.maskView.alpha = 0
        }) { _ in
            
            self.maskView.isHidden = true
        }
        
        circleLayer.removeFromSuperlayer()
        pinLayer.removeFromSuperlayer()
        mapView.overlays.forEach({mapView.removeOverlay($0)})
        
    }
    
    func searchRoute() {
//        [m1, m2, m3]
            [m1]
            .enumerated().forEach { i, v in
            let directionRequest = MKDirections.Request()
            directionRequest.source = MKMapItem(placemark: MKPlacemark(coordinate: v))
            directionRequest.destination = MKMapItem(placemark: MKPlacemark(coordinate: center))
            directionRequest.transportType = .automobile
            
            let directions = MKDirections(request: directionRequest)
            
            directions.calculate { (r, e) in
                guard let r = r else {  return }
                self.routes[i] = r.routes[0]
            }
        }
    }
    
    func showRoute(_ remove: Bool = false) {
        
        //        routes[0]
//        mapView.addOverlays(routes.map({$0.polyline}), level: .aboveLabels)
       
        routes.forEach {
            if (remove) {
                animateRemove(route: $0.polyline.coordinates , duration: 1) {
                    
                }
            } else {
                animate(route: $0.polyline.coordinates , duration: 1) {
                    
                }
            }
        }
        
        
    }
    
    
    var polyline: MKPolyline!
    func animateRemove(route: [CLLocationCoordinate2D], duration: TimeInterval, completion: (() -> Void)?) {
        guard route.count > 0 else { return }
        var currentStep = 1
        let totalSteps = route.count
        let stepDrawDuration = duration/TimeInterval(totalSteps)
        var previousSegment: MKPolyline?
        
        drawingTimer = Timer.scheduledTimer(withTimeInterval: stepDrawDuration, repeats: true) { [weak self] timer in
            guard let self = self else {
                // Invalidate animation if we can't retain self
                timer.invalidate()
                completion?()
                return
            }
            
            if let previous = previousSegment {
                // Remove last drawn segment if needed.
                self.mapView.removeOverlay(previous)
                previousSegment = nil
            }
            
            guard currentStep < totalSteps else {
                // If this is the last animation step...
                let finalPolyline = MKPolyline(coordinates: route, count: route.count)
                finalPolyline.title = "remove"
                self.mapView.addOverlay(finalPolyline)
                // Assign the final polyline instance to the class property.
                self.polyline = finalPolyline
                timer.invalidate()
                completion?()
                return
            }
            
            // Animation step.
            // The current segment to draw consists of a coordinate array from 0 to the 'currentStep' taken from the route.
            let subCoordinates = Array(route.prefix(upTo: currentStep))
            let currentSegment = MKPolyline(coordinates: subCoordinates, count: subCoordinates.count)
            currentSegment.title = "remove"
            self.mapView.addOverlay(currentSegment)
            
            previousSegment = currentSegment
            currentStep += 1
        }
    }
    
    func animate(route: [CLLocationCoordinate2D], duration: TimeInterval, completion: (() -> Void)?) {
        guard route.count > 0 else { return }
        var currentStep = 1
        let totalSteps = route.count
        let stepDrawDuration = duration/TimeInterval(totalSteps)
        var previousSegment: MKPolyline?
        
        drawingTimer = Timer.scheduledTimer(withTimeInterval: stepDrawDuration, repeats: true) { [weak self] timer in
            guard let self = self else {
                // Invalidate animation if we can't retain self
                timer.invalidate()
                completion?()
                return
            }
            
            if let previous = previousSegment {
                // Remove last drawn segment if needed.
                self.mapView.removeOverlay(previous)
                previousSegment = nil
            }
            
            guard currentStep < totalSteps else {
                // If this is the last animation step...
                let finalPolyline = MKPolyline(coordinates: route, count: route.count)
                self.mapView.addOverlay(finalPolyline)
                // Assign the final polyline instance to the class property.
                self.polyline = finalPolyline
                timer.invalidate()
                completion?()
                return
            }
            
            // Animation step.
            // The current segment to draw consists of a coordinate array from 0 to the 'currentStep' taken from the route.
            let subCoordinates = Array(route.prefix(upTo: currentStep))
            let currentSegment = MKPolyline(coordinates: subCoordinates, count: subCoordinates.count)
            self.mapView.addOverlay(currentSegment)
            
            previousSegment = currentSegment
            currentStep += 1
        }
    }
    
    
}

public extension MKMultiPoint {
    var coordinates: [CLLocationCoordinate2D] {
        var coords = [CLLocationCoordinate2D](repeating: kCLLocationCoordinate2DInvalid,
                                              count: pointCount)

        getCoordinates(&coords, range: NSRange(location: 0, length: pointCount))

        return coords
    }
}

//   Pin Animation
extension MainViewController {
    
    func setUpLayers() {
        
        circleLayer.lineWidth = 1
        circleLayer.strokeColor = UIColor.white.cgColor
        circleLayer.fillColor = UIColor.clear.cgColor
        circleLayer.path = UIBezierPath(ovalIn: circleView.bounds).cgPath
        
        circleLayer.shadowColor = UIColor.white.cgColor
        
        pinLayer.fillColor = UIColor.white.cgColor
        pinLayer.path = UIBezierPath(roundedRect: pinView.bounds, cornerRadius: 1).cgPath
        pinLayer.opacity = 0.9
    }
    
    func pinAnimation() {
        setUpLayers()
        
        circleView.layer.addSublayer(circleLayer)
        
        self.circleView.transform = CGAffineTransform(scaleX: 0.01, y: 0.01)
        self.circleView.alpha = 1
        
        UIView.animate(withDuration: 2, delay: 0, options: [.repeat], animations: {
            self.circleView.transform = CGAffineTransform(scaleX: 1, y: 1)
            self.circleView.alpha = 0
            
        }, completion: nil)
        
        
        pinView.layer.addSublayer(pinLayer)
        UIView.animate(withDuration: 1, delay: 0, options: [.curveEaseIn, .repeat, .autoreverse], animations: {
            
            self.pinView.transform = CGAffineTransform(translationX: 0, y: -4)
            self.pinView.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
            
            
        }, completion: nil)
    }
}


extension MainViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        
        if let overlay = overlay as? MKPolyline {
            let polyline = MKPolylineRenderer(overlay: overlay)
            if overlay.title == "remove" {
                polyline.strokeColor = #colorLiteral(red: 0.2522767484, green: 0.266956836, blue: 0.2797476053, alpha: 1)
                polyline.lineWidth = 2
            } else {
                polyline.strokeColor = .white
                polyline.lineWidth = 2
            }

            return polyline
        }
        
        return MKOverlayRenderer(overlay: overlay)
    }
}
