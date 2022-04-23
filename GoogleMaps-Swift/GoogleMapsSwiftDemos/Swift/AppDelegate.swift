// Copyright 2020 Google LLC. All rights reserved.
//
//
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use this
// file except in compliance with the License. You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software distributed under
// the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF
// ANY KIND, either express or implied. See the License for the specific language governing
// permissions and limitations under the License.

import GoogleMaps
import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

  var window: UIWindow?

  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    GMSServices.provideAPIKey(SDKConstants.apiKey)

      // setupAppOriginal()
      setupAppBroken()
      // setupAppModified()




    return true
  }

    private func setupAppOriginal() {
        let sampleListViewController = SampleListViewController()
        let frame = UIScreen.main.bounds
        let window = UIWindow(frame: frame)
        let navigationController = UINavigationController(rootViewController: sampleListViewController)
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
        self.window = window

        /// Depending on the mapView config and zoom level, pushing TransitViewController to navigation controller stack seems to work fine.
        /// Sometimes it crashes, sometimes it doesn't.
    }

    private func setupAppBroken() {
        let transitViewController = TransitViewController()
        let frame = UIScreen.main.bounds
        let window = UIWindow(frame: frame)
        let navigationController = UINavigationController(rootViewController: transitViewController)
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
        self.window = window

        /// Changing the map zoom level around makes this work. Seems to crash at 17 for current mapView config using this window setup.
        /// https://stackoverflow.com/questions/48274324/google-map-crash-at-specific-location-and-zoom-level-15/50818477#50818477
        /// https://issuetracker.google.com/issues/35829548
    }

    private func setupAppModified() {
        let transitViewController = TransitViewController()
        let frame = UIScreen.main.bounds
        let window = UIWindow(frame: frame)
        window.rootViewController = transitViewController
        window.makeKeyAndVisible()
        self.window = window

        /// No problems with zoom level when setting up the window this way.
    }
}
