import CoreGraphics
import Foundation

/// Latitude / longitude pair from a Strava encoded polyline.
struct GeoPoint: Equatable, Sendable {
    var latitude: Double
    var longitude: Double
}

/// Google encoded-polyline (precision 1e5), the format Strava uses for `summary_polyline`.
enum PolylineCodec: Sendable {
    static let precision = 1e5

    /// Well-known three-point sample from Google's polyline docs.
    static let googleSample = "_p~iF~ps|U_ulLnnqC_mqNvxq`@"

    /// Compact open-water loop used by previews and ReviewRecording.
    static let sampleSwim = #"_mr{FsulLwCGoCQ_COiBFmAp@q@fBS~CDnE^fFp@fF`AnEhA~ClAfBlAp@lAFhAOfAQdAGdAFfAPhANlAGlAq@lAgBhA_D`AoEp@gF^gFDoES_Dq@gBmAq@iBG_CNoCPwCF"#

    /// Elongated road loop used by previews and ReviewRecording.
    static let sampleBike = #"_ks{F_~`LoPct@_NcmAsS{_BsIcfBvLsrBb[syAzh@{fA~u@kf@~u@nP~f@r`AvVbfB~CnoBgOjlBsb@bfB{r@fpAku@vo@sg@nF"#

    /// Tighter urban block used by previews and ReviewRecording.
    static let sampleRun = #"g_r{F_mfLc[oA{YwG_SgToF_]~Cka@fOsSv[oFj\~CbV~RjMn_@bBfc@wLvVwVnF"#

    static func decode(_ encoded: String) -> [GeoPoint] {
        let trimmed = encoded.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else { return [] }

        let bytes = Array(trimmed.utf8)
        var index = 0
        var lat = 0
        var lng = 0
        var points: [GeoPoint] = []

        while index < bytes.count {
            guard let dlat = nextDelta(bytes: bytes, index: &index) else { break }
            guard let dlng = nextDelta(bytes: bytes, index: &index) else { break }
            lat += dlat
            lng += dlng
            points.append(
                GeoPoint(
                    latitude: Double(lat) / precision,
                    longitude: Double(lng) / precision
                )
            )
        }
        return points
    }

    static func encode(_ points: [GeoPoint]) -> String {
        var output = ""
        var previousLat = 0
        var previousLng = 0
        for point in points {
            let lat = Int((point.latitude * precision).rounded())
            let lng = Int((point.longitude * precision).rounded())
            output.append(encodeChunk(lat - previousLat))
            output.append(encodeChunk(lng - previousLng))
            previousLat = lat
            previousLng = lng
        }
        return output
    }

    /// A track is drawable when it has two points that actually move on the map.
    static func isDrawable(_ points: [GeoPoint]) -> Bool {
        guard points.count >= 2 else { return false }
        let latitudes = points.map(\.latitude)
        let longitudes = points.map(\.longitude)
        guard
            let minLat = latitudes.min(),
            let maxLat = latitudes.max(),
            let minLng = longitudes.min(),
            let maxLng = longitudes.max()
        else {
            return false
        }
        let span = max(maxLat - minLat, maxLng - minLng)
        // About five meters — a single GPS ping is not a route.
        return span > 0.00005
    }

    static func usesFallback(_ encoded: String?) -> Bool {
        isDrawable(decode(encoded ?? "")) == false
    }

    /// Fits longitude → x, latitude → y (north up), preserving aspect ratio inside `rect`.
    static func points(fitting points: [GeoPoint], in rect: CGRect) -> [CGPoint] {
        guard isDrawable(points) else { return [] }
        let latitudes = points.map(\.latitude)
        let longitudes = points.map(\.longitude)
        guard
            let minLat = latitudes.min(),
            let maxLat = latitudes.max(),
            let minLng = longitudes.min(),
            let maxLng = longitudes.max()
        else {
            return []
        }

        let latSpan = max(maxLat - minLat, 1e-9)
        let lngSpan = max(maxLng - minLng, 1e-9)
        let dataAspect = lngSpan / latSpan
        let rectAspect = rect.width / max(rect.height, 1)
        var draw = rect
        if dataAspect > rectAspect {
            let height = rect.width / dataAspect
            draw.origin.y += (rect.height - height) / 2
            draw.size.height = height
        } else {
            let width = rect.height * dataAspect
            draw.origin.x += (rect.width - width) / 2
            draw.size.width = width
        }

        return points.map { point in
            CGPoint(
                x: draw.minX + CGFloat((point.longitude - minLng) / lngSpan) * draw.width,
                y: draw.maxY - CGFloat((point.latitude - minLat) / latSpan) * draw.height
            )
        }
    }

    private static func nextDelta(bytes: [UInt8], index: inout Int) -> Int? {
        var result = 0
        var shift = 0
        while index < bytes.count {
            let value = Int(bytes[index]) - 63
            index += 1
            result |= (value & 0x1F) << shift
            shift += 5
            if value < 0x20 {
                return (result & 1) != 0 ? ~(result >> 1) : (result >> 1)
            }
        }
        return nil
    }

    private static func encodeChunk(_ value: Int) -> String {
        var chunk = value < 0 ? ~(value << 1) : (value << 1)
        var output = ""
        while chunk >= 0x20 {
            let ascii = UInt8((0x20 | (chunk & 0x1F)) + 63)
            output.append(Character(UnicodeScalar(ascii)))
            chunk >>= 5
        }
        let ascii = UInt8(chunk + 63)
        output.append(Character(UnicodeScalar(ascii)))
        return output
    }
}
