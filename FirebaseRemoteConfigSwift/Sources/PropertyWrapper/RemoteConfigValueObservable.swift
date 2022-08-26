/*
 * Copyright 2022 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import SwiftUI
import FirebaseRemoteConfig

@available(iOS 14.0, macOS 11.0, macCatalyst 14.0, tvOS 14.0, watchOS 7.0, *)
internal class RemoteConfigValueObservable<T: Decodable>: ObservableObject {
  @Published var configValue: T
  private let key: String
  private let remoteConfig: RemoteConfig
  private var registration: FIRConfigUpdateListenerRegistration?

  init(key: String, fallbackValue: T) {
    self.key = key
    self.remoteConfig = RemoteConfig.remoteConfig()
    // Initialize with fallback value
    self.configValue = fallbackValue
    // Check cached remote config value
    do {
      if let value : T = try self.remoteConfig[key].decoded() {
        switch T.self {
        case is String.Type:
          let stringValue = value as! String
          if (stringValue.isEmpty) {
            self.configValue = fallbackValue
          }
        default:
          self.configValue = value
        }
      }
    } catch {
      self.configValue = fallbackValue
    }

    // This will turn on real time update for all configs
    let currentRegister = self.remoteConfig.add(onConfigUpdateListener: { error in
      guard error == nil else {
        return
      }
      self.remoteConfig.activate { changed, error in
        guard error == nil else {
          return
        }
        DispatchQueue.main.async {
          do {
            self.configValue = try self.remoteConfig[key].decoded()
          } catch {
            self.configValue = fallbackValue
          }
        }
      }
    })
    self.registration = currentRegister
  }

  deinit {
    self.registration?.remove()
  }
}