/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A type which loads and tracks virtual objects.
*/

import Foundation
import ARKit

/**
 Loads multiple `VirtualObject`s on a background queue to be able to display the
 objects quickly once they are needed.
*/
enum VirtualObjectLoaderResult {
    case success([VirtualObject])
    case failed
}

class VirtualObjectLoader {
	private(set) var loadedObjects = [VirtualObject]()
    
    private(set) var isLoading = false
	
	// MARK: - Loading object

    /**
     Loads a `VirtualObject` on a background queue. `loadedHandler` is invoked
     on a background queue once `object` has been loaded.
    */

    func loadVirtualObject(name: String, count:Int = 1, completion: @escaping (VirtualObjectLoaderResult) -> Void) {
        
        guard let filePath = Bundle.main.path(forResource: name, ofType: "scn", inDirectory: "Models.scnassets/\(name)")  else {
            completion(.failed)
            return
        }
        let referenceURL = URL(fileURLWithPath: filePath)
        guard let node = VirtualObject(url: referenceURL)  else {
            completion(.failed)
            return
        }
        isLoading = true
        
        // Load the content asynchronously.
        DispatchQueue.global(qos: .userInitiated).async {
            node.reset()
            node.load()
            var nodes = [node]
            for _ in  0..<count {
                let copyNode = node.copy() as! VirtualObject
                nodes.append(copyNode)
            }
            self.loadedObjects.append(contentsOf: nodes)
            self.isLoading = false
            completion(.success(nodes))
        }
    }
    
    
    // MARK: - Removing Objects
    
    func removeAllVirtualObjects() {
        // Reverse the indices so we don't trample over indices as objects are removed.
        for index in loadedObjects.indices.reversed() {
            removeVirtualObject(at: index)
        }
    }
    
    func removeVirtualObject(at index: Int) {
        guard loadedObjects.indices.contains(index) else { return }
        
        loadedObjects[index].removeFromParentNode()
        loadedObjects.remove(at: index)
    }
}
