/*
See LICENSE folder for this sample’s licensing information.

Abstract:
UI Actions for the main view controller.
*/

import UIKit
import SceneKit

extension MoneyViewController: UIGestureRecognizerDelegate {
    
    enum SegueIdentifier: String {
        case showObjects
    }
    
    // MARK: - Interface Actions
    
    @IBAction func showVirtualObjectSelectionViewController() {
        performSegue(withIdentifier: SegueIdentifier.showObjects.rawValue, sender: addObjectButton)
    }
    
    /// Determines if the tap gesture for presenting the `VirtualObjectSelectionViewController` should be used.
    func gestureRecognizerShouldBegin(_: UIGestureRecognizer) -> Bool {
        return virtualObjectLoader.loadedObjects.isEmpty
    }
    
    func gestureRecognizer(_: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith _: UIGestureRecognizer) -> Bool {
        return true
    }
    
    /// - Tag: restartExperience
    func restartExperience() {
        guard isRestartAvailable, !virtualObjectLoader.isLoading else { return }
        isRestartAvailable = false
        self.loadingState = .notReady

        statusViewController.cancelAllScheduledMessages()
        statusViewController.hideSalaryTextView()

        virtualObjectLoader.removeAllVirtualObjects()
        
        let node = sceneView.scene.rootNode.childNode(withName: "savings", recursively: true)
        node?.removeFromParentNode()
        
        resetTracking()
        
        
        // Disable restart for a while in order to give the session time to restart.
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            self.isRestartAvailable = true
            self.loadingState = .ready
        }
    }
}

extension MoneyViewController: UIPopoverPresentationControllerDelegate {
    
    // MARK: - UIPopoverPresentationControllerDelegate
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // All menus should be popovers (even on iPhone).
        if let popoverController = segue.destination.popoverPresentationController, let button = sender as? UIButton {
            popoverController.delegate = self
            popoverController.sourceView = button
            popoverController.sourceRect = button.bounds
        }
        
        guard let identifier = segue.identifier,
            let segueIdentifer = SegueIdentifier(rawValue: identifier),
            segueIdentifer == .showObjects else { return }
        
        
    }
    
    func popoverPresentationControllerDidDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) {
        //objectsViewController = nil
    }
}
