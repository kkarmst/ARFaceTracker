//
//  ViewController.swift
//  FaceTracker
//
//  Created by Kieran Armstrong on 2020-05-20.
//  Copyright © 2020 Kieran Armstrong. All rights reserved.
//

import UIKit
import ARKit
import SceneKit
import Foundation
import AVFoundation

class FaceTrackingViewController: UIViewController, ARSessionDelegate {
    
    // MARK - UIOutlets
    
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet var saveButton: UIButton!
    
    // MARK: Properties
    private let ini = UserDefaults.standard  // Store user setting
    
    // Display content properties
    var contentControllers: [VirtualContentType: VirtualContentController] = [:]
    var currentFaceAnchor: ARFaceAnchor?
    var selectedVirtualContent: VirtualContentType! {
        didSet {
            guard oldValue != nil, oldValue != selectedVirtualContent
                else { return }
            
            // Remove existing content when switching types.
            contentControllers[oldValue]?.contentNode?.removeFromParentNode()
            
            // If there's an anchor already (switching content), get the content controller to place initial content.
            // Otherwise, the content controller will place it in `renderer(_:didAdd:for:)`.
            if let anchor = currentFaceAnchor, let node = sceneView.node(for: anchor),
                let newContent = selectedContentController.renderer(sceneView, nodeFor: anchor) {
                node.addChildNode(newContent)
            }
        }
    }
    var selectedContentController: VirtualContentController {
        if let controller = contentControllers[selectedVirtualContent] {
            return controller
        } else {
            let controller = selectedVirtualContent.makeController()
            contentControllers[selectedVirtualContent] = controller
            return controller
        }
    }
    
    // Capture properites
    //    var session: ARSession {
    //        return sceneView.session
    //    }
    
    var isCapturing = false {
        didSet {
            
        }
    }
    
    var captureMode = CaptureMode.record
    
    // Streaming mode properties
    var host = "192.168.86.24" {
        didSet {
            ini.set(host, forKey: "host")
        }
    }
    var port = 2020 {
        didSet {
            ini.set(port, forKey: "port")
        }
    }
    
    var inStream: InputStream!
    var outStream: OutputStream!
    var connect: Bool = true
    
    // Record mode Properites
    var fps = 30.0 {
        didSet {
            fps = min(max(fps, 1.0), 60.0)
            ini.set(fps, forKey: "fps")
        }
    }
    var fpsTimer: Timer!
    var captureData: [CaptureData]!
    var currentCaptureFrame = 0
    var folderPath : URL!
    
    // Queue Properties
    private let saveQueue = DispatchQueue.init(label: "save.queue")
    private let dispatchGroup = DispatchGroup()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        sceneView.delegate = self
        sceneView.session.delegate = self
        sceneView.automaticallyUpdatesLighting = true
        selectedVirtualContent = VirtualContentType.texture
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        initARFaceTracking()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
    
    // MARK: - ARSessionDelegate
    func session(_ session: ARSession, didFailWithError error: Error) {
        if captureMode == .record {
//            recordData()
        }
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        return
    }
    func sessionInterruptionEnded(_ session: ARSession) {
        DispatchQueue.main.async {
            self.initARFaceTracking()
        }
    }
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        // When capture mode is stream, execute streaming here
    }
    
    // MARK: - ARFaceTrackingSetup
    func initARFaceTracking() {
        guard ARFaceTrackingConfiguration.isSupported else { return }
        let configuration = ARFaceTrackingConfiguration()
        configuration.isLightEstimationEnabled = false
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    // MARK: - Error handling
    
    func displayErrorMessage(title: String, message: String) {
        // Present an alert informing about the error that has occurred.
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let restartAction = UIAlertAction(title: "Restart Session", style: .default) { _ in
            alertController.dismiss(animated: true, completion: nil)
            self.initARFaceTracking()
        }
        alertController.addAction(restartAction)
        present(alertController, animated: true, completion: nil)
    }
    
    // MARK: - IBAction
    
    @IBAction func saveButtonTapped(_ sender: UIButton) {
        guard let data = getFrameData() else {return}
        let jsonDataString = String(decoding: data.jsonData, as: UTF8.self)
        print(jsonDataString)
    }
    
    // MARK: - Frame Data Handling
    func recordData() {
        guard let data = getFrameData() else {return}
        captureData.append(data)

    }
    
    func getFrameData() -> CaptureData? { // Organize arkit's data
           let arFrame = sceneView.session.currentFrame!
           guard let anchor = arFrame.anchors[0] as? ARFaceAnchor else {return nil}
           let vertices = anchor.geometry.vertices
           let data = CaptureData(vertices: vertices)
           return data
       }
    
}

extension FaceTrackingViewController: ARSCNViewDelegate {

    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let faceAnchor = anchor as? ARFaceAnchor else { return }
        currentFaceAnchor = faceAnchor

        // If this is the first time with this anchor, get the controller to create content.
        // Otherwise (switching content), will change content when setting `selectedVirtualContent`.
        if node.childNodes.isEmpty, let contentNode = selectedContentController.renderer(renderer, nodeFor: faceAnchor) {
            node.addChildNode(contentNode)
        }

        // Get the currernt frame for AprilTag detection
        selectedContentController.session = sceneView.session
        selectedContentController.sceneView = sceneView

//        print(currentFaceAnchor?.rightEyeTransform.columns.3 ?? 0)
    }

    /// - Tag: ARFaceGeometryUpdate
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard anchor == currentFaceAnchor,
            let contentNode = selectedContentController.contentNode,
            contentNode.parent == node
            else { return }

        selectedContentController.session = sceneView.session
        selectedContentController.sceneView = sceneView
        selectedContentController.renderer(renderer, didUpdate: contentNode, for: anchor)
    }

}

