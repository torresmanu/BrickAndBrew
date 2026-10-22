import Foundation
import MapKit

/// On-device Apple Maps lookup for drink venues. Fail closed on errors.
enum VenuePlaceClassifier {
    private static let categories: [MKPointOfInterestCategory] = [
        .nightlife,
        .brewery,
        .restaurant
    ]

    static func nearestDrinkVenue(
        at coordinate: VenuePingPlanner.Coordinate
    ) async -> VenuePingPlanner.NearbyPOI? {
        let center = CLLocationCoordinate2D(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let request = MKLocalPointsOfInterestRequest(
            center: center,
            radius: VenuePingPlanner.poiRadiusMeters
        )
        request.pointOfInterestFilter = MKPointOfInterestFilter(including: categories)
        let search = MKLocalSearch(request: request)
        do {
            let response = try await search.start()
            let origin = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            let matches: [VenuePingPlanner.NearbyPOI] = response.mapItems.compactMap { item in
                let name = item.name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                guard name.isEmpty == false else { return nil }
                let location = item.placemark.location ?? CLLocation(
                    latitude: item.placemark.coordinate.latitude,
                    longitude: item.placemark.coordinate.longitude
                )
                let distance = origin.distance(from: location)
                guard distance <= VenuePingPlanner.poiRadiusMeters else { return nil }
                return VenuePingPlanner.NearbyPOI(
                    name: name,
                    coordinate: VenuePingPlanner.Coordinate(
                        latitude: location.coordinate.latitude,
                        longitude: location.coordinate.longitude
                    ),
                    distanceMeters: distance
                )
            }
            return matches.min(by: { $0.distanceMeters < $1.distanceMeters })
        } catch {
            return nil
        }
    }

    /// Human line for a saved pin. Falls back if reverse geocode is unavailable.
    static func addressLabel(for location: CLLocation) async -> String {
        let geocoder = CLGeocoder()
        do {
            let marks = try await geocoder.reverseGeocodeLocation(location)
            guard let mark = marks.first else { return VenuePingCopy.fallbackLabel }
            let street = [mark.subThoroughfare, mark.thoroughfare]
                .compactMap { $0 }
                .joined(separator: " ")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if street.isEmpty == false { return street }
            if let locality = mark.locality, locality.isEmpty == false { return locality }
            if let name = mark.name, name.isEmpty == false { return name }
            return VenuePingCopy.fallbackLabel
        } catch {
            return VenuePingCopy.fallbackLabel
        }
    }
}
