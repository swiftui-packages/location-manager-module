//
//  LocationManager.swift
//  LocationManagerModule
//
//  Created by Cem Yilmaz on 20.08.21.
//

import MapKit

#if canImport(UIKit)
public class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private var locationManager: CLLocationManager = CLLocationManager()

    public init(requestLocation: Bool = false) {
        super.init()
        self.locationManager.delegate = self
        if requestLocation {
            try? self.requestLocationAccess()
        }
        self.clearGeofences()
        self.activeGeofences = self.locationManager.monitoredRegions.count
        self.updateAuthorizationStatus()
    }

    // true, false, nil -> can be requested
    @Published public var userIsLocatable: Bool?

    private func updateAuthorizationStatus() {
        if self.locationManager.authorizationStatus == .authorizedAlways ||
           self.locationManager.authorizationStatus == .authorizedWhenInUse {
            self.userIsLocatable = true
        } else if self.locationManager.authorizationStatus == .denied {
            self.userIsLocatable = false
        } else if self.locationManager.authorizationStatus == .notDetermined {
            self.userIsLocatable = nil
        }
    }

    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        self.updateAuthorizationStatus()
    }

    public func getUserLocation() -> CLLocationCoordinate2D? {
        return self.locationManager.location?.coordinate
    }

    public func requestLocationAccess() throws {
        if self.locationManager.authorizationStatus == .notDetermined {
            self.locationManager.requestWhenInUseAuthorization()
        } else if self.locationManager.authorizationStatus == .denied ||
          self.locationManager.authorizationStatus == .restricted {
            throw LocationError.locationRequestNotPossible
        }
    }

    public func openAppSettings() {
        if let settingsULR = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsULR, options: [:], completionHandler: nil)
        }
    }

    enum LocationError: Error {
        case locationRequestNotPossible
    }

    // Geofencing
    // Accuracy +/- 150m and often time delayed

    @Published public var activeGeofences: Int = 0

    public func getGeofences() -> [CLCircularRegion] {
        self.locationManager.monitoredRegions.compactMap { region in
            region as? CLCircularRegion
        }
    }

    private var didEnterGeofencedRegion: ((_ identifier: String) -> Void)?
    private var didLeaveGeofencedRegion: ((_ identifier: String) -> Void)?

    public func setActionForEnteringGeofencedRegion(didEnterGeofencedRegion: @escaping (_ identifier: String) -> Void) {
        self.didEnterGeofencedRegion = didEnterGeofencedRegion
    }

    public func setActionForLeavingGeofencedRegion(didLeaveGeofencedRegion: @escaping (_ identifier: String) -> Void) {
        self.didLeaveGeofencedRegion = didLeaveGeofencedRegion
    }

    public func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        if let onEnterRegion = self.didEnterGeofencedRegion {
            onEnterRegion(region.identifier)
        }
    }

    public func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        if let onLeaveRegion = self.didLeaveGeofencedRegion {
            onLeaveRegion(region.identifier)
        }
    }

    public func addGeofence(forRegion region: CLCircularRegion) {
        self.locationManager.startMonitoring(for: region)
    }

    public func addGeofences(forRegions regions: [CLCircularRegion]) {
        regions.forEach { region in
            self.addGeofence(forRegion: region)
        }
    }

    public func removeGeofence(forRegion region: CLCircularRegion) {
        self.locationManager.stopMonitoring(for: region)
    }

    public func removeGeofence(forRegions regions: [CLCircularRegion]) {
        regions.forEach { region in
            self.removeGeofence(forRegion: region)
        }
    }

    public func clearGeofences() {
        self.locationManager.monitoredRegions.forEach { region in
            self.locationManager.stopMonitoring(for: region)
        }
    }

    public func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
        self.activeGeofences = manager.monitoredRegions.count
    }
}
#endif
