//
//  EventsModalTableViewController.swift
//  Cru
//
//  Created by Max Crane on 4/14/16.
//  Copyright © 2016 Jamaican Hopscotch Mafia. All rights reserved.
//

import UIKit

class EventsModalTableViewController: UITableViewController {
    var events = [Event]()
    var vc: OfferRideViewController?
    var fvc: FilterByEventViewController?
    var offerRide: OfferOrEditRideViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        events.sort(by: {$0.name < $1.name})
    }

    // MARK: - TableView Methods
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return events.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)

        cell.textLabel!.text = events[indexPath.row].name
        cell.textLabel!.font = UIFont(name: Config.fontName, size: 18.0)
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let vc = self.vc {
            vc.eventName.text = tableView.cellForRow(at: indexPath)?.textLabel?.text
            vc.chosenEvent = events[indexPath.row]
            vc.formHasBeenEdited = true
        } else if let fvc = self.fvc {
            fvc.eventNameLabel.text = tableView.cellForRow(at: indexPath)?.textLabel?.text
            fvc.selectedEvent = events[indexPath.row]
        } else if let offerRide = self.offerRide {
            offerRide.ride.eventId = events[indexPath.row].id
            offerRide.ride.eventName = events[indexPath.row].name
            offerRide.ride.eventStartDate = events[indexPath.row].startNSDate
            offerRide.ride.eventEndDate = events[indexPath.row].endNSDate
            offerRide.event = events[indexPath.row]
            offerRide.updateOptions()
        }
        
        self.dismiss(animated: true)
    }
}
