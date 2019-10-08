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
let m1 = CLLocationCoordinate2D(latitude: 1.278015, longitude: 103.858439)
let m2 = CLLocationCoordinate2D(latitude: 1.299943, longitude: 103.855426)
let m3 = CLLocationCoordinate2D(latitude: 1.272613, longitude: 103.837920)


let fromDistance: CLLocationDistance = 6000
let rangeDistance: CLLocationDistance =  1000
let pitch: CGFloat = 60
let heading: CLLocationDirection = 180

class MainViewController: UIViewController {
    
    let mkCamera = MKMapCamera(lookingAtCenter: center, fromDistance: rangeDistance, pitch: 0, heading: 0)
    
    var coordinates = [CLLocationCoordinate2D]()
    
    let circleLayer = CAShapeLayer()
    let pinLayer = CAShapeLayer()
    
    private var drawingTimer: Timer?
    var routes = [MKRoute(), MKRoute(), MKRoute()]
    
    var timer: Timer?
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var maskView: UIView!
    
    @IBOutlet weak var circleView: UIView!
    @IBOutlet weak var pinView: UIView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        searchNearbyCoordinates()
        
        mapView.setCamera(mkCamera, animated: false)
    }
    
    
    @IBAction func rotate(_ sender: UIButton) {
        
        UIView.animate(withDuration: 1) { [weak self] in
            self?.maskView.isHidden = false
        }
        
        UIView.animate(withDuration: 1, delay: 0, options: .curveEaseInOut, animations: {  [weak self] in
            self?.mapView.setCamera(MKMapCamera(lookingAtCenter: center, fromDistance: fromDistance, pitch: pitch, heading: 0), animated: true)
        }) { b in
            self.pinAnimation()
            UIView.animate(withDuration: 180, delay: 0, options: [.curveLinear, .autoreverse], animations: {  [weak self] in
                self?.mapView.setCamera(MKMapCamera(lookingAtCenter: center, fromDistance: fromDistance, pitch: pitch, heading: heading), animated: true)
            }, completion: nil)
        }
        
        timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] timer in
            self?.searchRoute()
            self?.showRoute()
        }
    }
    
    
    @IBAction func resetAction(_ sender: UIButton) {
        
        timer?.invalidate()
        
        UIView.animate(withDuration: 1, animations: {  [weak self] in
            guard let self = self else { return }
            self.mapView.setCamera(self.mkCamera, animated: true)
            self.maskView.alpha = 0
        }) { _ in
            self.maskView.isHidden = true
        }
        
        circleLayer.removeFromSuperlayer()
        pinLayer.removeFromSuperlayer()
        mapView.overlays.forEach({mapView.removeOverlay($0)})
        
    }
    
    func searchNearbyCoordinates() {
        let req = MKLocalSearch.Request()
        req.naturalLanguageQuery = "mrt"
        req.region = MKCoordinateRegion(center: center, latitudinalMeters: 3000, longitudinalMeters: 3000)
        let localSearch = MKLocalSearch(request: req)
        localSearch.start { [weak self] (response, error) in
            guard error == nil else { return }
            self?.coordinates = response?.mapItems.compactMap({$0.placemark.coordinate}).filter({
                MKMapPoint($0).distance(to: MKMapPoint(center)) > 1000
            }) ?? [m1, m2, m3]
            self?.searchRoute()
        }
    }
    
    func searchRoute() {
        coordinates.shuffled()[0..<3].enumerated().forEach { [weak self] i, v in
            let req = MKDirections.Request()
            req.source = MKMapItem(placemark: MKPlacemark(coordinate: v))
            req.destination = MKMapItem(placemark: MKPlacemark(coordinate: center))
            req.transportType = .automobile
            
            let directions = MKDirections(request: req)
            
            directions.calculate { (r, e) in
                guard let r = r else {  return }
                self?.routes[i] = r.routes[0]
            }
        }
    }
    
    func showRoute(_ remove: Bool = false) {
        routes.forEach {
            animate(route: $0.polyline.coordinates , duration: 1.5)
        }
        
    }
    
    func animate(route: [CLLocationCoordinate2D], duration: TimeInterval, completion: (() -> Void)? = nil) {
        guard route.count > 0 else { return }
        var currentStep = 0
        let delta = 25, opt = 3.0
        let totalSteps = route.count + delta
        let stepDrawDur = duration / TimeInterval(totalSteps) * opt
        var prePolyline: MKPolyline?
        
        drawingTimer = Timer.scheduledTimer(withTimeInterval: stepDrawDur, repeats: true) { [weak self] timer in
            defer { completion?() }
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            if let previous = prePolyline {
                self.mapView.removeOverlay(previous)
                prePolyline = nil
            }
            
            if currentStep > totalSteps {
                timer.invalidate()
                return
            }
            
            let start = currentStep-delta < 0 ? 0 : currentStep-delta
            let end = currentStep > route.count ? route.count : currentStep
            
            let subCoordinates = Array(route[start..<end])
            let currentSegment = MKPolyline(coordinates: subCoordinates, count: subCoordinates.count)
            self.mapView.addOverlay(currentSegment)
            
            prePolyline = currentSegment
            currentStep += Int(opt)
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
        
        circleLayer.lineWidth = 1.5
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
        
        UIView.animate(withDuration: 2, delay: 0, options: [.repeat], animations: { [weak self] in
            self?.circleView.transform = CGAffineTransform(scaleX: 1, y: 1)
            self?.circleView.alpha = 0
            
        }, completion: nil)
        
        
        pinView.layer.addSublayer(pinLayer)
        UIView.animate(withDuration: 1, delay: 0, options: [.curveEaseIn, .repeat, .autoreverse], animations: {  [weak self] in
            
            self?.pinView.transform = CGAffineTransform(translationX: 0, y: -4)
            self?.pinView.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
            
            
        }, completion: nil)
    }
}


extension MainViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        
        if let overlay = overlay as? MKPolyline {
            let polyline = MKPolylineRenderer(overlay: overlay)
            polyline.strokeColor = .white
            polyline.lineWidth = 1.5
            return polyline
        }
        
        return MKOverlayRenderer(overlay: overlay)
    }
}
