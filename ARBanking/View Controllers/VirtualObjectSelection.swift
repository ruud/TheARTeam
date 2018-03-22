/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Popover view controller for choosing virtual objects to place in the AR scene.
*/

import UIKit
import ARKit

// MARK: - ObjectCell

class ObjectCell: UITableViewCell {
    static let reuseIdentifier = "ObjectCell"
    
    @IBOutlet weak var objectTitleLabel: UILabel!
    @IBOutlet weak var objectImageView: UIImageView!
	@IBOutlet weak var vibrancyView: UIVisualEffectView!
	
    var modelName = "" {
        didSet {
            objectTitleLabel.text = modelName.capitalized
            objectImageView.image = UIImage(named: modelName)
            objectTitleLabel.textColor = UIColor.black
        }
    }
}

// MARK: - VirtualObjectSelectionViewControllerDelegate

/// A protocol for reporting which objects have been selected.
protocol VirtualObjectSelectionViewControllerDelegate: class {
    func virtualObjectSelectionViewController(_ selectionViewController: VirtualObjectSelectionViewController, didSelectObject: VirtualObject)
    func virtualObjectSelectionViewController(_ selectionViewController: VirtualObjectSelectionViewController, didDeselectObject: VirtualObject)
}

/// A custom table view controller to allow users to select `VirtualObject`s for placement in the scene.
class VirtualObjectSelectionViewController: UITableViewController {
    
    /// The collection of `VirtualObject`s to select from.
    var virtualObjects = [String]()
    
    /// The rows of the currently selected `VirtualObject`s.
    var selectedVirtualObjectRows = IndexSet()
	
	/// The rows of the 'VirtualObject's that are currently allowed to be placed.
	var enabledVirtualObjectRows = Set<Int>()
    
    weak var delegate: VirtualObjectSelectionViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.separatorEffect = UIVibrancyEffect(blurEffect: UIBlurEffect(style: .light))
    }
    
    override func viewWillLayoutSubviews() {
        preferredContentSize = CGSize(width: 250, height: tableView.contentSize.height)
    }
	
    
    // MARK: - UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		
        
        // Check if the current row is already selected, then deselect it.
        // TODO
        dismiss(animated: true, completion: nil)
    }
        
    // MARK: - UITableViewDataSource
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ObjectCell.reuseIdentifier, for: indexPath) as? ObjectCell else {
            fatalError("Expected `\(ObjectCell.self)` type for reuseIdentifier \(ObjectCell.reuseIdentifier). Check the configuration in Main.storyboard.")
        }
        
        cell.modelName = "test"

        if selectedVirtualObjectRows.contains(indexPath.row) {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
		
//        let cellIsEnabled = enabledVirtualObjectRows.contains(indexPath.row)
//        if cellIsEnabled {
//            cell.vibrancyView.alpha = 1.0
//        } else {
//            cell.vibrancyView.alpha = 0.1
//        }

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
//        let cellIsEnabled = enabledVirtualObjectRows.contains(indexPath.row)
//        guard cellIsEnabled else { return }
//
//        let cell = tableView.cellForRow(at: indexPath)
//        cell?.backgroundColor = UIColor.lightGray.withAlphaComponent(0.5)
    }
    
    override func tableView(_ tableView: UITableView, didUnhighlightRowAt indexPath: IndexPath) {
//        let cellIsEnabled = enabledVirtualObjectRows.contains(indexPath.row)
//        guard cellIsEnabled else { return }
//
//        let cell = tableView.cellForRow(at: indexPath)
//        cell?.backgroundColor = .clear
    }
}
