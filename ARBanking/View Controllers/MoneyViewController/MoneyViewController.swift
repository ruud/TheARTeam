/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Main view controller for the AR experience.
*/

import ARKit
import SceneKit
import UIKit

enum MoneyLoadingState {
    case notReady, ready, loading, loaded
}

enum MoneyModels: Int {
    case bill5, bill10, bill20, bill50, bill100, bill200, bill500
    var name: String {
        switch self {
        case .bill5:
            return "5bill"
        case .bill10:
            return "10bill"
        case .bill20:
            return "20bill"
        case .bill50:
            return "50bill"
        case .bill100:
            return "100bill"
        case .bill200:
            return "200bill"
        case .bill500:
            return "500bill"
        }
    }
}

class MoneyViewController: UIViewController {
    
    // MARK: IBOutlets
    
    @IBOutlet var sceneView: VirtualObjectARView!
    
    @IBOutlet weak var blurView: UIVisualEffectView!
    
    @IBOutlet weak var spinner: UIActivityIndicatorView!

    // MARK: - UI Elements
    
    @IBOutlet weak var addObjectButton: UIButton!
    var focusSquare = FocusSquare()
    
    /// The view controller that displays the status and "restart experience" UI.
    lazy var statusViewController: StatusViewController = {
        return childViewControllers.lazy.flatMap({ $0 as? StatusViewController }).first!
    }()
	
    // MARK: - ARKit Configuration Properties
    
    /// A type which manages gesture manipulation of virtual content in the scene.
    lazy var virtualObjectInteraction = VirtualObjectInteraction(sceneView: sceneView)
    
    /// Coordinates the loading and unloading of reference nodes for virtual objects.
    let virtualObjectLoader = VirtualObjectLoader()
    
    /// Marks if the AR experience is available for restart.
    var isRestartAvailable = true
    
    var loadingState: MoneyLoadingState = .notReady
    
    /// A serial queue used to coordinate adding or removing nodes from the scene.
    let updateQueue = DispatchQueue(label: "com.example.apple-samplecode.arkitexample.serialSceneKitQueue")
    
    var screenCenter: CGPoint {
        let bounds = sceneView.bounds
        return CGPoint(x: bounds.midX, y: bounds.midY)
    }
    
    /// Convenience accessor for the session owned by ARSCNView.
    var session: ARSession {
        return sceneView.session
    }
    
    // MARK: - View Controller Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.delegate = self
        sceneView.session.delegate = self

        // Set up scene content.
        setupCamera()
        sceneView.scene.rootNode.addChildNode(focusSquare)

        /*
         The `sceneView.automaticallyUpdatesLighting` option creates an
         ambient light source and modulates its intensity. This sample app
         instead modulates a global lighting environment map for use with
         physically based materials, so disable automatic lighting.
         */
        sceneView.automaticallyUpdatesLighting = false
        if let environmentMap = UIImage(named: "Models.scnassets/sharedImages/environment_blur.exr") {
            sceneView.scene.lightingEnvironment.contents = environmentMap
        }

        // Hook up status view controller callback(s).
        statusViewController.restartExperienceHandler = { [unowned self] in
            self.restartExperience()
        }
    }
    
    @objc func loadMoney() {
        loadMoneyModel(index: 0)
    }
    
    func loadMoneyModel(index: Int) {
        guard let model = MoneyModels(rawValue: index) else { return }
        let count = Int(arc4random_uniform(UInt32(5)))
        virtualObjectLoader.loadVirtualObject(name: model.name, count: count, completion: { [unowned self] result in
            switch result {
            case .failed:
                self.loadingState = .ready
            case .success(let nodes):
                DispatchQueue.main.async {
                    self.hideObjectLoadingUI()
                    nodes.forEach{ self.placeVirtualObject($0) }
                    self.loadingState = .loaded
                    self.loadMoneyModel(index: index + 1)
                }
            }
        })
        DispatchQueue.main.async {
            self.displayObjectLoadingUI()
        }
    }

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		// Prevent the screen from being dimmed to avoid interuppting the AR experience.
		UIApplication.shared.isIdleTimerDisabled = true

        // Start the `ARSession`.
        resetTracking()
        loadingState = .ready

	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)

        session.pause()
	}

    // MARK: - Scene content setup

    func setupCamera() {
        guard let camera = sceneView.pointOfView?.camera else {
            fatalError("Expected a valid `pointOfView` from the scene.")
        }

        /*
         Enable HDR camera settings for the most realistic appearance
         with environmental lighting and physically based materials.
         */
        camera.wantsHDR = true
        camera.exposureOffset = -1
        camera.minimumExposure = -1
        camera.maximumExposure = 3
    }

    // MARK: - Session management
    
    /// Creates a new AR configuration to run on the `session`.
	func resetTracking() {
		virtualObjectInteraction.selectedObject = nil
		
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal]
		session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        statusViewController.scheduleMessage("FIND A SURFACE TO PLACE AN OBJECT", inSeconds: 7.5, messageType: .planeEstimation)
	}

    // MARK: - Focus Square

	func updateFocusSquare() {
        
        guard loadingState == .ready else {
            return
        }
        
        let isObjectVisible = virtualObjectLoader.loadedObjects.contains { object in
            return sceneView.isNode(object, insideFrustumOf: sceneView.pointOfView!)
        }
        
        if isObjectVisible {
            focusSquare.hide()
        } else {
            //focusSquare.unhide()
            statusViewController.scheduleMessage("TRY MOVING LEFT OR RIGHT", inSeconds: 5.0, messageType: .focusSquare)
        }
		
		if let result = self.sceneView.smartHitTest(screenCenter, allowedAlignments: [.horizontal]) {
			updateQueue.async {
				self.sceneView.scene.rootNode.addChildNode(self.focusSquare)
				let camera = self.session.currentFrame?.camera
				self.focusSquare.state = .detecting(hitTestResult: result, camera: camera)
			}
            if (result.anchor as? ARPlaneAnchor) != nil {
                self.foundPlane()
            }
		} else {
			updateQueue.async {
				self.focusSquare.state = .initializing
				self.sceneView.pointOfView?.addChildNode(self.focusSquare)
			}
			return
		}
		
        statusViewController.cancelScheduledMessage(for: .focusSquare)
	}
    
	// MARK: - Error handling
    
    func displayErrorMessage(title: String, message: String) {
        // Blur the background.
        blurView.isHidden = false
        
        // Present an alert informing about the error that has occurred.
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let restartAction = UIAlertAction(title: "Restart Session", style: .default) { _ in
            alertController.dismiss(animated: true, completion: nil)
            self.blurView.isHidden = true
            self.resetTracking()
        }
        alertController.addAction(restartAction)
        present(alertController, animated: true, completion: nil)
    }

}

// MARK: Place Objects

extension MoneyViewController {
    /**
     Adds the specified virtual object to the scene, placed using
     the focus square's estimate of the world-space position
     currently corresponding to the center of the screen.
     
     - Tag: PlaceVirtualObject
     */
    func placeVirtualObject(_ virtualObject: VirtualObject) {
        guard let cameraTransform = session.currentFrame?.camera.transform,
            let focusSquareAlignment = focusSquare.recentFocusSquareAlignments.last,
            focusSquare.state != .initializing else {
                statusViewController.showMessage("CANNOT PLACE OBJECT\nTry moving left or right.")
                return
        }
        
        // The focus square transform may contain a scale component, so reset scale to 1
        let focusSquareScaleInverse = 1.0 / focusSquare.simdScale.x
        let scaleMatrix = float4x4(uniformScale: focusSquareScaleInverse)
        let focusSquareTransformWithoutScale = focusSquare.simdWorldTransform * scaleMatrix
        
        // Add physics
//        let startPos = virtualObject.position
//        virtualObject.position = SCNVector3Make(startPos.x, startPos.y - 1.0, startPos.z)
//        virtualObject.physicsBody = SCNPhysicsBody(type: SCNPhysicsBodyType.dynamic, shape: nil)

        virtualObjectInteraction.selectedObject = virtualObject
        virtualObject.setTransform(focusSquareTransformWithoutScale,
                                   relativeTo: cameraTransform,
                                   smoothMovement: false,
                                   alignment: focusSquareAlignment,
                                   allowAnimation: false)
        
        updateQueue.async {
            self.sceneView.scene.rootNode.addChildNode(virtualObject)
            self.sceneView.addOrUpdateAnchor(for: virtualObject)
        }
    }
    
    // MARK: Object Loading UI
    
    func displayObjectLoadingUI() {
        // Show progress indicator.
        spinner.startAnimating()
        isRestartAvailable = false
    }
    
    func hideObjectLoadingUI() {
        // Hide progress indicator.
        spinner.stopAnimating()
        isRestartAvailable = true
    }

    func foundPlane() {
        if loadingState == .ready {
            loadMoney()
            loadingState = .loading
        }
    }
}

