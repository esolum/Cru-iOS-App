//
//  MinistryTeamCell.swift
//  Cru
//
//  Created by Tyler Dahl on 7/6/17.
//  Copyright © 2017 Jamaican Hopscotch Mafia. All rights reserved.
//

import UIKit

protocol MinistryTeamSignUpDelegate {
    func signUpForMinistryTeam(_ ministryTeam: MinistryTeam)
}

class MinistryTeamCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var teamNameLabel: UILabel!
    @IBOutlet weak var leaderNamesLabel: UILabel!
    @IBOutlet weak var ministryNameLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var signUpButton: UIButton!
    @IBOutlet weak var stackViewTopConstraint: NSLayoutConstraint!
    
    var delegate: MinistryTeamSignUpDelegate?
    
    var ministryTeam: MinistryTeam! {
        didSet {
            self.teamNameLabel.text = self.ministryTeam.ministryName
            self.ministryNameLabel.text = self.ministryTeam.parentMinistry
            self.descriptionLabel.text = self.ministryTeam.description
            
            // Default text in case the leader names don't exist
            self.leaderNamesLabel.text = "Led by awesome people :)"
            if !self.ministryTeam.leaders.isEmpty {
                let leaderNames = self.ministryTeam.leaders.map{$0.name}.filter{!$0.isEmpty}
                if !leaderNames.isEmpty {
                    self.leaderNamesLabel.text = leaderNames.reduce(leaderNames.first!) {"\($0), \($1)"}
                }
            }
            
            // Set the image if it exists
            if ministryTeam.imageUrl == "" {
                self.imageView.image = nil
                self.imageView.isHidden = true
                self.stackViewTopConstraint.constant = 8
            } else {
                self.imageView.load.request(with: self.ministryTeam.imageUrl)
                self.imageView.isHidden = false
                self.stackViewTopConstraint.constant = 0
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        //Add drop shadow
        self.backgroundView?.layer.shadowColor = UIColor.black.cgColor
        self.backgroundView?.layer.shadowOffset = CGSize(width: 0, height: 1)
        self.backgroundView?.layer.shadowOpacity = 0.25
        self.backgroundView?.layer.shadowRadius = 2
        self.backgroundView?.clipsToBounds = false
    }

    @IBAction func signUpPressed() {
        self.delegate?.signUpForMinistryTeam(self.ministryTeam)
    }
    
    // Override this method to allow dynamically sized collection view cells
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let originalFrame = self.frame
        
        // Update the cell size and layout the contents
        self.frame.size = size
        self.setNeedsLayout()
        self.layoutIfNeeded()
        
        // Get the updated size
        let computedSize = self.systemLayoutSizeFitting(UILayoutFittingCompressedSize)
        
        // Create the final size using the given width and computed height
        let newSize = CGSize(width: size.width, height: computedSize.height)
        
        // Reset the cell's frame to before we modified it
        self.frame = originalFrame
        
        return newSize
    }
}
