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
            zoom: 14)
        return GMSMapView(frame: .zero, camera: camera)
    }()

    private lazy var markerIconView: UIView = {
        let view = UIView.init(frame: .init(x: 0, y: 0, width: 20, height: 20))
        view.backgroundColor = .white
        if #available(iOS 13.0, *) {
            view.layer.borderColor = .init(red: 0, green: 0, blue: 1, alpha: 1)
        }
        view.layer.borderWidth = 5
        view.layer.cornerRadius = view.bounds.width/2
        return view
    }()

    private enum Places: String {
        case MedgarEversCollege = "place_id:ChIJzVCft3ZbwokRlCL7B6LA8U4"
        case TimesSquare = "place_id:ChIJmQJIxlVYwokRLgeuocVOGVU"
        case BarclaysCenter = "place_id:ChIJo3lEaa5bwokRnuZS2oWTlLk"

        /// https://developers.google.com/maps/documentation/places/web-service/place-id#find-id
    }

    override func loadView() {
        view = mapView
        mapView.accessibilityElementsHidden = true

        fetchDirections(from: .MedgarEversCollege, to: .TimesSquare) { [self] result in
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

    private func fetchDirections(from: Places, to: Places, completion: @escaping ((AFResult<JSON>) -> Void)) {
        struct Parameters: Encodable {
            let origin: String
            let destination: String
            let mode: String
            let key: String
        }

        let parameters = Parameters(
            origin: from.rawValue,
            destination: to.rawValue,
            mode: "transit",
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
        let polylinePath: String = json["routes"][0]["overview_polyline"]["points"].stringValue
        debugPrint(polylinePath)

        let polyline: GMSPolyline = .init(path: .init(fromEncodedPath: polylinePath))
        polyline.strokeWidth = 5
        polyline.strokeColor = .blue
        polyline.map = self.mapView

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

        /// fill in path legs (stops)
        let steps = json["routes"][0]["legs"][0]["steps"]

        for i in 0..<steps.count {

            var marker: GMSMarker

            if i == steps.count-1 {
                /// plot the end location of this last step

                let position = CLLocationCoordinate2D(
                    latitude: steps[i]["end_location"]["lat"].doubleValue,
                    longitude: steps[i]["end_location"]["lng"].doubleValue)

                marker = GMSMarker(position: position)
                print(position)

            } else {
                /// plot the start location of the current step

                let position = CLLocationCoordinate2D(
                    latitude: steps[i]["start_location"]["lat"].doubleValue,
                    longitude: steps[i]["start_location"]["lng"].doubleValue)

                marker = GMSMarker(position: position)
                print(position)
            }

            marker.iconView = markerIconView
            marker.map = mapView
        }
    }
}

