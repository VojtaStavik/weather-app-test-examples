//
//  WeatherApp - SwiftUI
//
//  Copyright (c) 2020 Industrial Binaries
//  MIT license, see LICENSE file for details
//

@testable import WeatherApp_SwiftUI

import Combine
import CombineTestExtensions
import SnapshotTesting
import SwiftUI
import XCTest

class WeatherViewTests: XCTestCase {
  var sut: WeatherView!

  var scheduler: TestScheduler!

  var cancellables: [AnyCancellable]!

  override func setUp() {
    super.setUp()

    scheduler = .init()
    cancellables = []

    XCTAssertEqual(UIScreen.main.scale, 2, "Snapshots are valid only for @2 scale")
  }

  override func tearDown() {
    sut = nil
    super.tearDown()
  }

  func testLoadingData() {
    let vm = TestViewModel()
    sut = WeatherView(viewModel: vm)

    vm.set(state: .loading)

    let hostingVC = UIHostingController(rootView: sut)
    hostingVC.view.layer.speed = 0

    assertSnapshot(matching: hostingVC, as: .image(on: .iPhoneX))
  }

  func testErrorState() {
    let vm = TestViewModel()
    sut = WeatherView(viewModel: vm)

    vm.set(state: .error)

    let hostingVC = UIHostingController(rootView: sut)

    assertSnapshot(matching: hostingVC, as: .image(on: .iPhoneX))
  }

  func testLoadedData() {
    let vm = TestViewModel()
    vm.set(state: .loaded(
      weatherDescription: "Amazingly sunny",
      temperature: "112 °C",
      icon: "🚀",
      location: "Virtual"
    ))
    sut = WeatherView(viewModel: vm)

    let hostingVC = UIHostingController(rootView: sut)

    assertSnapshot(matching: hostingVC, as: .image(on: .iPhoneX))
  }

  func testLikeDislikeButtonTap() {
    let vm = TestViewModel()
    vm.set(state: .loaded(
      weatherDescription: "Amazingly sunny",
      temperature: "112 °C",
      icon: "🚀",
      location: "Virtual"
    ))

    let sut = WeatherView(viewModel: vm)

    let like = vm.likeButtonTapped.record()
    let dislike = vm.dislikeButtonTapped.record()

    sut.simulateInteraction {
      $0.tap(WeatherView.UIIdentifiers.likeButton)
      $0.tap(WeatherView.UIIdentifiers.dislikeButton)
    }

    XCTAssertEqual(like.records.count, 1)
    XCTAssertEqual(dislike.records.count, 1)
  }
}

extension View {
  func simulateInteraction(_ actions: (Interactor<Self>) -> Void) {
    let interactor = Interactor(view: self)
    // Without this call, looking up a specific accessibilityIdentifier often fails.
    UIApplication.shared.accessibilityActivate()
    
    actions(interactor)
  }
}

struct Interactor<V: View> {
  private let window: UIWindow
  private let hostingVC: UIHostingController<V>

  func tap(_ accessibilityIdentifier: String, file: StaticString = #file, line: UInt = #line) {
    let view = hostingVC.view!
    let element = view.accessibilityElement { $0?.accessibilityIdentifier == accessibilityIdentifier }
    guard let rect = element?.accessibilityFrame
    else {
      XCTFail("Can't find elemnet with accessibility id \(accessibilityIdentifier).", file: file, line: line)
      return
    }

    view.tap(at: .init(x: rect.midX, y: rect.midY))
  }

  init(view: V) {
    window = UIWindow()
    hostingVC = UIHostingController(rootView: view)
    window.rootViewController = hostingVC

    let view = hostingVC.view!

    view.frame = window.bounds
    view.layoutIfNeeded()

    window.isHidden = false
  }
}
