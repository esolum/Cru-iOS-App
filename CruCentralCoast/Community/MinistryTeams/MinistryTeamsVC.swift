//
//  MinistryTeamsVC.swift
//  CruCentralCoast
//
//  Created by Landon Gerrits on 5/30/18.
//  Copyright © 2018 Landon Gerrits. All rights reserved.
//

import UIKit
import RealmSwift

class MinistryTeamsVC: UITableViewController {
    
    var dataArray: Results<MinistryTeam>!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.insertProfileButtonInNavBar()
        self.tableView.registerCell(MinistryTeamCell.self)

        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 140
        
        DatabaseManager.instance.subscribeToDatabaseUpdates(self)
        self.dataArray = DatabaseManager.instance.getMinistryTeams()
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.dataArray.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueCell(MinistryTeamCell.self, indexPath: indexPath)

        cell.configure(with: self.dataArray[indexPath.row])
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let vc = UIStoryboard(name: "MinistryTeams", bundle: nil).instantiateViewController(MinistryTeamDetailsVC.self)
        vc.configure(with: self.dataArray[indexPath.row])
        self.navigationController?.present(vc, animated: true, completion: nil)
    }
}

extension MinistryTeamsVC: DatabaseListenerProtocol {
    func updatedMinistryTeams() {
        print("Ministry Teams were updated - refreshing UI")
        self.tableView.reloadData()
    }
}