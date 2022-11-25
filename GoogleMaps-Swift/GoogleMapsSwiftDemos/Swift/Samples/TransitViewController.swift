//
//  TransitViewController.swift
//  GoogleMapsSwiftDemos
//
//  Created by Isiah Manns on 3/14/22.
//

import Alamofire
import GoogleMaps
import UIKit
import SwiftyJSON

final class TransitViewController: UIViewController {

    private lazy var mapView: GMSMapView = {
        let camera = GMSCameraPosition(
            latitude: 40.670884415976886,
            longitude: -73.958119273615,
            zoom: 17)

        let mapID = GMSMapID(identifier: SDKConstants.MapID.transit)

        return GMSMapView(frame: .zero, mapID: mapID, camera: camera)
    }()

    private enum Places: String {
        case MedgarEversCollege = "place_id:ChIJzVCft3ZbwokRlCL7B6LA8U4"
        case TimesSquare = "place_id:ChIJmQJIxlVYwokRLgeuocVOGVU"
        case BarclaysCenter = "place_id:ChIJo3lEaa5bwokRnuZS2oWTlLk"
        case FlatbushAvStation = "place_id:ChIJxXVHnlJbwokRfPknIQCZkSw"
        case WakefieldStation = "place_id:ChIJM_TmzNHywokR2WYmgb0rF38"

        /// https://developers.google.com/maps/documentation/places/web-service/place-id#find-id
    }

    override func loadView() {
        view = mapView
        mapView.accessibilityElementsHidden = true

        fetchDirections(from: .FlatbushAvStation, to: .WakefieldStation) { [self] result in
            switch result {
            case let .failure(error):
                debugPrint(error)
            case let .success(json):
                self.updateMap(json: json)
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }

    private func fetchDirections(from: Places, to: Places, completion: @escaping ((AFResult<JSON>) -> Void)) {

        /// check "cache" (use this for quick map debugging)
        /*
        if let path = Bundle.main.path(forResource: "MedgarEversCollegeToTimesSquare", ofType: "json"),
           let jsonString = try? String(contentsOfFile: path) {

            let jsonObject = JSON(parseJSON: jsonString)
            completion(.success(jsonObject))
            return
        }
         */

        struct Parameters: Encodable {
            let origin: String
            let destination: String
            let mode: String
            let alternatives: String
            let key: String
        }

        let parameters = Parameters(
            origin: from.rawValue,
            destination: to.rawValue,
            mode: "transit",
            alternatives: "true",
            key: SDKConstants.apiKey)

        /// begin request
        AF.request("https://maps.googleapis.com/maps/api/directions/json",
                   method: .get,
                   parameters: parameters,
                   encoder: URLEncodedFormParameterEncoder.default).validate().responseData { response in

            switch response.result {
            case let .failure(error):
                completion(.failure(error))

            case let .success(data):
                debugPrint(response)

                guard let json = try? JSON(data: data) else {
                    debugPrint("problem creating SwiftyJSON object")
                    return
                }

                completion(.success(json))
            }
        } /// end request
    }

    private func updateMap(json: JSON) {
        /// show path on map
        let steps = json["routes"][0]["legs"][0]["steps"]

        let styles = [
          GMSStrokeStyle.solidColor(.darkGray),
          GMSStrokeStyle.solidColor(.clear)
        ]

        let lengths: [NSNumber] = [25, 25]

        for i in 0..<steps.count {
            /// plot polylines and markers
            let polylinePath: String = steps[i]["polyline"]["points"].stringValue
            let polyline = GMSPolyline(path: GMSPath(fromEncodedPath: polylinePath))
            polyline.strokeWidth = 5

            let startLocation = CLLocationCoordinate2D(
                latitude: steps[i]["start_location"]["lat"].doubleValue,
                longitude: steps[i]["start_location"]["lng"].doubleValue)

            let endLocation = CLLocationCoordinate2D(
                latitude: steps[i]["end_location"]["lat"].doubleValue,
                longitude: steps[i]["end_location"]["lng"].doubleValue)

            let startMarker = GMSMarker(position: startLocation)
            let endMarker = GMSMarker(position: endLocation)

            if steps[i]["travel_mode"].stringValue == "WALKING" {
                polyline.spans = GMSStyleSpans(polyline.path!,
                                               styles,
                                               lengths,
                                               .rhumb)

                (startMarker.iconView, endMarker.iconView) = markerIconViewsWalking()
                [startMarker, endMarker].forEach { $0.zIndex = Int32(0) }
            }

            if steps[i]["travel_mode"].stringValue == "TRANSIT" {
                let lineColorHex = steps[i]["transit_details"]["line"]["color"].stringValue
                let lineColor = UIColor(hex: lineColorHex)
                polyline.strokeColor = lineColor

                (startMarker.iconView, endMarker.iconView) = markerIconViewsTransit(color: lineColor)
                [startMarker, endMarker].forEach { $0.zIndex = Int32(1) }
            }

            polyline.map = mapView
            startMarker.map = mapView
            endMarker.map = mapView
        }


        /// update camera
        let polylineBounds = json["routes"][0]["bounds"]

        let cameraUpdate = GMSCameraUpdate.fit(
            .init(coordinate: .init(
                latitude: polylineBounds["northeast"]["lat"].doubleValue,
                longitude: polylineBounds["northeast"]["lng"].doubleValue),
                  coordinate: .init(
                    latitude: polylineBounds["southwest"]["lat"].doubleValue,
                    longitude: polylineBounds["southwest"]["lng"].doubleValue)),
            with: .init(top: 30, left: 30, bottom: 0.5*UIScreen.main.bounds.height, right: 30))

        mapView.animate(with: cameraUpdate)
    }
}

private func markerIconViewsTransit(color: UIColor) -> (UIView, UIView) {
    let view = UIView.init(frame: .init(x: 0, y: 0, width: 20, height: 20))
    view.backgroundColor = .white
    view.layer.borderColor = color.cgColor
    view.layer.borderWidth = 5
    view.layer.cornerRadius = view.bounds.width / 2

    return (view, view)
}

private func markerIconViewsWalking() -> (UIView, UIView) {
    let startView = UIView.init(frame: .init(x: 0, y: 0, width: 20, height: 20))
    startView.backgroundColor = .white
    startView.layer.borderColor = UIColor.darkGray.cgColor
    startView.layer.borderWidth = 5
    startView.layer.cornerRadius = startView.bounds.width / 2

    let endView = UIView.init(frame: .init(x: 0, y: 0, width: 20, height: 20))
    endView.backgroundColor = UIColor.darkGray
    endView.layer.cornerRadius = endView.bounds.width / 2

    return (startView, endView)
}

extension UIColor {
    convenience init(hex: String, alpha: CGFloat = 1) {
        assert(hex.count == 7)
        assert(hex.hasPrefix("#"))
        let clippedHexString = hex.suffix(6)

        let hexColors: [Int] = stride(from: 0, to: clippedHexString.count, by: 2)
            .map { index in
                let lowerBound = String.Index(utf16Offset: index, in: clippedHexString)
                let upperBound = String.Index(utf16Offset: index + 2, in: clippedHexString)
                return clippedHexString[lowerBound..<upperBound]
            }
            .map { hexSubstring in
                guard let hexInt = Int(hexSubstring, radix: 16) else { fatalError() }
                return hexInt
            }

        let maxIntensity = 255.0
        let r = CGFloat(hexColors[0]) / maxIntensity
        let g = CGFloat(hexColors[1]) / maxIntensity
        let b = CGFloat(hexColors[2]) / maxIntensity

        self.init(red: r, green: g, blue: b, alpha: alpha)
    }
}
