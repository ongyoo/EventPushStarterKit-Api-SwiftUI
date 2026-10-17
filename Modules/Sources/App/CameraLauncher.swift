//
//  CameraLauncher.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 17/10/2569 BE.
//

import Core
import PhotosUI
import UIKit

/// The tab bar's camera button: the camera when the device has one,
/// the photo library otherwise (Simulator). Not a tab: it presents over
/// whatever tab is open.
@MainActor
enum CameraLauncher {
    static func present(from presenter: UIViewController, analytics: any AnalyticsTracking = Container.shared.analytics()) {
        analytics.track(AnalyticsEvent("camera_opened", ["source": .string(UIImagePickerController.isSourceTypeAvailable(.camera) ? "camera" : "library")]))
        presenter.present(makePicker(), animated: true)
    }

    /// `prefersCamera: false` forces the library. The camera is used only when
    /// the device really has one (asking for it otherwise throws).
    static func makePicker(prefersCamera: Bool = true) -> UIViewController {
        if prefersCamera, UIImagePickerController.isSourceTypeAvailable(.camera) {
            let picker = UIImagePickerController()
            picker.sourceType = .camera
            picker.delegate = PickerCloser.shared
            return picker
        }
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 1
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = PickerCloser.shared
        return picker
    }
}

/// Closes the pickers. A real app would hand the photo to a feature here.
private final class PickerCloser: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate, PHPickerViewControllerDelegate {
    static let shared = PickerCloser()

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
    }
}
