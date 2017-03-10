 //
//  ResourcesViewController.swift
//  Cru
//  Formats and displays the resources in the Cru database as cards. Handles actions for full-screen view.
//
//  Created by Erica Solum on 2/18/15.
//  Copyright © 2015 Jamaican Hopscotch Mafia. All rights reserved.
//

import UIKit
import WildcardSDK
import AVFoundation
import Alamofire
import HTMLReader
import MRProgress
import DZNEmptyDataSet
import ReadabilityKit

let InitialCount = 20
let PageSize = 8

class ResourcesViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITabBarDelegate, CardViewDelegate, SWRevealViewControllerDelegate, UIViewControllerTransitioningDelegate, Dimmable, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate, UIPopoverPresentationControllerDelegate {
    //MARK: Properties
    @IBOutlet weak var menuButton: UIBarButtonItem!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var selectorBar: UITabBar!
    @IBOutlet weak var searchButton: UIBarButtonItem!
    
    
    var serverClient: ServerProtocol
    var resources = [Resource]()
    var cardViews = [CardView]()
    var tags = [ResourceTag]()
    var overlayRunning = false
    var currentType = ResourceType.Article
    
    var articles = [Article]()
    var audioFiles = [Audio]()
    var videos = [Video]()
    var filteredArticles = [Article]()
    var filteredAudioFiles = [Audio]()
    var filteredVideos = [Video]()
    var selectedRow = -1
    
    
    
    
    var filteredResources = [Resource]()
    var articleViews = [CardView]()
    var audioViews = [CardView]()
    var videoViews = [CardView]()
    var allViews = [CardView]()
    var filteredArticleCards = [ArticleCard]()
    var filteredAudioCards = [SummaryCard]()
    var filteredVideoCards = [VideoCard]()
    var articleCards = [ArticleCard]()
    var audioCards = [SummaryCard]()
    var videoCards = [VideoCard]()
    
    var parser: Readability?
    var audioPlayer:AVAudioPlayer!
    var apiKey = "AIzaSyDW_36-r4zQNHYBk3Z8eg99yB0s2jx3kpc"
    var cruChannelID = "UCe-RJ-3Q3tUqJciItiZmjdg"
    var cruUploadsID = "UUe-RJ-3Q3tUqJciItiZmjdg"
    var videosArray: Array<Dictionary<NSObject, AnyObject>> = []
    var nextPageToken = ""
    var pageNum = 1
    let dimLevel: CGFloat = 0.5
    let dimSpeed: Double = 0.5
    var searchActivated = false
    var modalActive = false {
        didSet {
            if modalActive == true {
                searchButton.isEnabled = false
            }
            else {
                searchButton.isEnabled = true
            }
        }
    }
    var isLeader = false
    var filteredTags = [ResourceTag]()
    var searchPhrase = ""
    var hasConnection = true
    var emptyTableImage: UIImage!
    var numUploads: Int!
    var urlString: String!
    var noResultsString: NSAttributedString!
    var verticalContentOffset: CGFloat!
    var videoCardHeight: CGFloat!
    var memoryWarning = false
    
    //Call this constructor in testing with a fake serverProtocol
    init?(serverProtocol: ServerProtocol, _ coder: NSCoder? = nil) {
        //super.init(coder: NSCoder)
        self.serverClient = serverProtocol
    
        if let coder = coder {
            super.init(coder: coder)
        }
        else {
            super.init()
        }
        
    }

    required convenience init?(coder aDecoder: NSCoder) {
        //fatalError("init(coder:) has not been implemented")
        self.init(serverProtocol: CruClients.getServerClient(), aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        GlobalUtils.setupViewForSideMenu(self, menuButton: menuButton)

        selectorBar.selectedItem = selectorBar.items![0]
        self.tableView.delegate = self
        
        //Make the line between cells invisible
        tableView.separatorColor = UIColor.clear
        
        CruClients.getServerClient().checkConnection(self.finishConnectionCheck)
        
        
        
        
        tableView.backgroundColor = Colors.googleGray
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 150
        videoCardHeight = 0
        
        //Set the nav title
        navigationItem.title = "Resources"
        
        self.navigationController!.navigationBar.titleTextAttributes  = [ NSFontAttributeName: UIFont(name: Config.fontBold, size: 20)!, NSForegroundColorAttributeName: UIColor.white]
        
        selectorBar.tintColor = UIColor.white
        
        
        
        /* Uncomment this for a later release*/
        //addLeaderTab()

    }
    
    /* Don't load anymore youtube resources */
    override func didReceiveMemoryWarning() {
        memoryWarning = true
    }
    
    func doNothing(_ success: Bool) {
        
    }
    
    func addLeaderTab() {
        let articleTab = UITabBarItem(title: "Articles", image: UIImage(named: "article"), tag: 0)
        let videoTab = UITabBarItem(title: "Video", image: UIImage(named: "video"), tag: 1)
        let audioTab = UITabBarItem(title: "Audio", image: UIImage(named: "audio"), tag: 2)
        
        let leaderTab = UITabBarItem(title: "Leader", image: UIImage(named: "community-group-icon"), tag: 3)
        selectorBar.setItems([articleTab, videoTab, audioTab, leaderTab], animated: true)
    }
    
    /* Function for the empty data set */
    func image(forEmptyDataSet scrollView: UIScrollView!) -> UIImage! {
        return emptyTableImage
    }
    
    /* Text for the empty search results data set*/
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        //Set up attribute string for empty search results
        let attributes = [ NSFontAttributeName: UIFont(name: Config.fontName, size: 18)!, NSForegroundColorAttributeName: UIColor.black]
        
        if hasConnection {
            if searchActivated && searchPhrase != ""{
                switch (currentType){
                case .Article:
                    noResultsString = NSAttributedString(string: "No articles found with the phrase \(searchPhrase)", attributes: attributes)
                case .Audio:
                    noResultsString = NSAttributedString(string: "No audio resources found with the phrase \(searchPhrase)", attributes: attributes)
                case .Video:
                    noResultsString = NSAttributedString(string: "No videos found with the phrase \(searchPhrase)", attributes: attributes)
                }
                
            }
            else {
                switch (currentType){
                case .Article:
                    noResultsString = NSAttributedString(string: "No article resources found", attributes: attributes)
                case .Audio:
                    noResultsString = NSAttributedString(string: "No audio resources found", attributes: attributes)
                case .Video:
                    noResultsString = NSAttributedString(string: "No video resources found", attributes: attributes)
                }
            }
            
            
        }
        
        return noResultsString
    }
    
    //Test to make sure there is a connection then load resources
    func finishConnectionCheck(_ connected: Bool){
        if(!connected){
            hasConnection = false
            self.emptyTableImage = UIImage(named: Config.noConnectionImageName)
            self.tableView.emptyDataSetDelegate = self
            self.tableView.emptyDataSetSource = self
            self.tableView.reloadData()
            //hasConnection = false
        }else{
            hasConnection = true
            
            MRProgressOverlayView.showOverlayAdded(to: self.view, animated: true)
            overlayRunning = true
            //serverClient.getData(DBCollection.Resource, insert: insertResource, completionHandler: getVideosForChannel)
            serverClient.getData(DBCollection.Resource, insert: insertResource, completionHandler: finished)
            
            //Also get resource tags and store them
            serverClient.getData(DBCollection.ResourceTags, insert: insertResourceTag, completionHandler: {_ in
                //Hide the community leader tag if the user isn't logged in
                if GlobalUtils.loadString(Config.leaderApiKey) == "" {
                    let index = self.tags.index(where: {$0.title == "Leader (password needed)"})
                    self.tags.remove(at: index!)
                    
                }
            })
        }
        
    }
    
    func insertResourceTag(_ dict : NSDictionary) {
        let tag = ResourceTag(dict: dict)!
        tags.insert(tag, at: 0)
        
        
    }
    
    
    //Code for the bar at the top of the view for filtering resources
    func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        var newType: ResourceType
        var oldTypeCount = 0
        var newTypeCount = 0
        
        //print("Selecting item: \(item.title)")
        
        switch (item.title!){
        case "Articles":
            newType = ResourceType.Article
            newTypeCount = articles.count
        case "Audio":
            newType = ResourceType.Audio
            newTypeCount = audioFiles.count
        case "Videos":
            newType = ResourceType.Video
            newTypeCount = videos.count
        default :
            newType = ResourceType.Article
            newTypeCount = articles.count
        }
        
        switch (currentType){
        case .Article:
            oldTypeCount = articles.count
        case .Audio:
            oldTypeCount = audioFiles.count
        case .Video:
            oldTypeCount = videos.count
        }
        
        
        if(newType == currentType){
            return
        }
        else{
            currentType = newType
        }
        self.tableView.reloadData()
    }
    
    //Get resources from database
    func insertResource(_ dict : NSDictionary) {
        let resource = Resource(dict: dict)!
        resources.insert(resource, at: 0)
        
        if (resource.type == ResourceType.Article) {
            insertArticle(resource, completionHandler: {_ in
                print("done inserting articles")
            })
            
            //print("Insert article here")
        }
            
        else if (resource.type == ResourceType.Video) {
            if(resource.url.range(of: "youtube") != nil) {
                //insertYoutube(resource, completionHandler: doNothing)
                print("insert youtube")
            }
            else {
                //insertGeneric(resource, completionHandler: doNothing)
                print("insert generic video")
            }
        }
            
        else if (resource.type == ResourceType.Audio) {
            insertAudio(resource, completionHandler: {_ in
                print("done inserting audio")
            })
        }
    }
    
    /* Implement when tools support is requested */
    fileprivate func insertAudio(_ resource: Resource, completionHandler: (Bool) -> Void) {
    
        /*var card: SummaryCard!
       
        let media:NSMutableDictionary = NSMutableDictionary()
        let data:NSMutableDictionary = NSMutableDictionary()
        
        media["type"] = "audio"
        data["tags"] = resource.tags
        
        let audioUrl = URL(string: resource.url)!
        card = SummaryCard(url:audioUrl, description: "This is where a description would go.", title: resource.title, media:media, data: data)
        
        self.audioCards.append(card)*/
        let newAud = Audio(id: resource.id, title: resource.title, url: resource.url, date: resource.date, tags: resource.tags, restricted: resource.restricted)!
        audioFiles.append(newAud)
    }
    
    
    /* Helper function to get and insert an article card */
    fileprivate func insertArticle(_ resource: Resource,completionHandler: (Bool) -> Void) {
        let resUrl = URL(string: resource.url)
        guard let url = resUrl else {
            return
        }
        
        Readability.parse(url: url) { data in
            
            
            /*guard let imageUrlStr = data?.topImage else {
                return
            }
            
            guard let imageUrl = URL(string: imageUrlStr) else {
                return
            }
            
            guard let imageData = try? Data(contentsOf: imageUrl) else {
                return
            }*/
            let title = data?.title ?? "Article"
            let description = data?.description ?? ""
            let keywords = data?.keywords ?? [""]
            let imageUrl = data?.topImage ?? ""
            let videoUrl = data?.topVideo ?? ""
            
            print("Readabilty found: ")
            print("Title: \(title)")
            print("Description: \(description)")
            print("Keywords: \(keywords)")
            print("ImageURL: \(imageUrl)")
            print("Video URL: \(videoUrl)")
            
            let newArt = Article(id: resource.id, title: resource.title, url: resource.url, date: resource.date, tags: resource.tags, abstract: description, imgURL: imageUrl, restricted: resource.restricted)
            self.articles.append(newArt!)
            self.tableView.reloadData()
            
        }
        
        
    }
    
    /* Inserts a video from a generic source */
    fileprivate func insertGeneric(_ resource: Resource,completionHandler: (Bool) -> Void) {
        Alamofire.request(resource.url, method: .get)
            .responseString { responseString in
                guard responseString.result.error == nil else {
                    //completionHandler(responseString.result.error!)
                    return
                    
                }
                guard let htmlAsString = responseString.result.value else {
                    //Future problem: impement better error code with Alamofire 4
                    print("Error: Could not get HTML as String")
                    return
                }
                
                var vidURL: String!
                
                let doc = HTMLDocument(string: htmlAsString)
                let content = doc.nodes(matchingSelector: "iframe")
                
                for vidEl in content {
                    let vidNode = vidEl.firstNode(matchingSelector: "iframe")!
                    vidURL = vidNode.objectForKeyedSubscript("src") as? String
                    
                    
                }
                
                var videoCard: VideoCard!
                
                let creator = Creator(name:"", url: URL(string:"http://icons.iconarchive.com/icons/iconsmind/outline/512/Open-Book-icon.png")!, favicon:URL(string:"http://icons.iconarchive.com/icons/iconsmind/outline/512/Open-Book-icon.png"), iosStore:nil)
              
                let youtubeID = self.getYoutubeID(vidURL)
                let embedUrl = URL(string: vidURL)!
                let vidwebUrl = URL(string: vidURL)!
                
                
                let videoData:NSMutableDictionary = NSMutableDictionary()
                let videoMedia:NSMutableDictionary = NSMutableDictionary()
                videoMedia["description"] =  ""
                videoMedia["posterImageUrl"] = "http://i1.ytimg.com/vi/\(youtubeID)/mqdefault.jpg"
                
                videoData["media"] = videoMedia
                videoData["tags"] = resource.tags
                
                videoCard = VideoCard(title: resource.title, embedUrl: embedUrl, url: vidwebUrl, creator: creator, data: videoData)
                self.videoCards.append(videoCard)
                
        }
    }
    
    //Get the id of the youtube video by searching within the URL
    fileprivate func getYoutubeID(_ url: String) -> String {
        let start = url.range(of: "embed/")
        if(start != nil) {
            let end = url.range(of: "?")
            
            if(end != nil) {
                return url.substring(with: (start!.upperBound ..< end!.lowerBound))
            }
        }
        return String("")
    }
    
    fileprivate func insertYoutube(_ resource: Resource,completionHandler: (Bool) -> Void) {
        var videoCard:VideoCard!
        
        let newUrl = URL(string: "http://www.youtube.com")!
        let embedUrl = URL(string: resource.url)!
        let vidwebUrl = URL(string: resource.url)!
        
        
        let youtube = Creator(name:"Youtube", url: newUrl, favicon:URL(string:"http://coopkanicstang-development.s3.amazonaws.com/brandlogos/logo-youtube.png"), iosStore:nil)
        
        
        let videoData:NSMutableDictionary = NSMutableDictionary()
        let videoMedia:NSMutableDictionary = NSMutableDictionary()
        videoMedia["description"] = ""
        videoMedia["posterImageUrl"] = "http://i1.ytimg.com/vi/\(getYoutubeID(resource.url))/mqdefault.jpg"
        
        videoData["media"] = videoMedia
        videoData["tags"] = resource.tags
        videoCard = VideoCard(title: resource.title, embedUrl: embedUrl, url: vidwebUrl, creator: youtube, data: videoData)
        
        self.videoCards.append(videoCard)
        
        
    }
    
    fileprivate func insertYoutubeFromChannel(_ resource: Resource, description: String, completionHandler: (Bool) -> Void) {
        var videoCard:VideoCard!
        
        let newUrl = URL(string: "http://www.youtube.com")
        
        print("embedUrl: https://www.youtube.com/embed/\(resource.id!)?rel=0")
        let embedUrl = URL(string: "https://www.youtube.com/embed/\(resource.id!)?rel=0")
        let vidwebUrl = URL(string: String("https://www.youtube.com/watch?v=\(resource.id!)"))
        
        
        let youtube = Creator(name:"Youtube", url: newUrl!, favicon:URL(string:"http://coopkanicstang-development.s3.amazonaws.com/brandlogos/logo-youtube.png"), iosStore:nil)
        
        
        let videoData:NSMutableDictionary = NSMutableDictionary()
        let videoMedia:NSMutableDictionary = NSMutableDictionary()
        videoMedia["description"] =  description
        videoMedia["posterImageUrl"] = "http://i1.ytimg.com/vi/\(resource.id)/mqdefault.jpg"
        
        
        videoData["media"] = videoMedia
        videoData["tags"] = []
        videoCard = VideoCard(title: resource.title, embedUrl: embedUrl!, url: vidwebUrl!, creator: youtube, data: videoData)
        
        self.videoCards.append(videoCard)
        self.resources.append(resource)
    }
    
    // MARK: Cru CC Youtube Video Retrieval
    //Get the data from Cru Central Coast's youtube channel
    func getVideosForChannel(_ success: Bool) {
        if !overlayRunning {
            MRProgressOverlayView.showOverlayAdded(to: self.view, animated: true)
            overlayRunning = true
        }
        
        // Get the selected channel's playlistID value from the channelsDataArray array and use it for fetching the proper video playlst.
        
        // Form the request URL string.
        self.urlString = "https://www.googleapis.com/youtube/v3/playlistItems?part=snippet&maxResults=\(PageSize)&playlistId=\(cruUploadsID)&key=\(apiKey)"
        
        if nextPageToken != "" {
            self.urlString = "https://www.googleapis.com/youtube/v3/playlistItems?part=snippet&maxResults=\(PageSize)&pageToken=\(nextPageToken)&playlistId=\(cruUploadsID)&key=\(apiKey)"
            
        }
        
        // Fetch the playlist from Google.
        performGetRequest(URL(string: self.urlString), completion: { (data, HTTPStatusCode, error) -> Void in
            if HTTPStatusCode == 200 && error == nil {
                // Convert the JSON data into a dictionary.
                do {
                    let resultsDict = try JSONSerialization.jsonObject(with: data!, options: []) as? Dictionary<String, AnyObject>
                    
                    
                    //Get next page token
                    self.nextPageToken = resultsDict?["nextPageToken"] as! String
                    self.numUploads = (resultsDict?["pageInfo"] as! Dictionary<String, AnyObject>)["totalResults"] as! Int
                    
                    // Get all playlist items ("items" array).
                    
                    let items: Array<Dictionary<String, AnyObject>> = resultsDict!["items"] as! Array<Dictionary<String, AnyObject>>
                    
                    // Use a loop to go through all video items.
                    for i in 0 ..< items.count {
                        let playlistSnippetDict = (items[i] as Dictionary<String, AnyObject>)["snippet"] as! Dictionary<String, AnyObject>
                        
                        // Initialize a new dictionary and store the data of interest.
                        var desiredPlaylistItemDataDict = Dictionary<String, AnyObject>()
                        
                        desiredPlaylistItemDataDict["title"] = playlistSnippetDict["title"]
                        desiredPlaylistItemDataDict["description"] = playlistSnippetDict["description"]
                        desiredPlaylistItemDataDict["thumbnail"] = ((playlistSnippetDict["thumbnails"] as! Dictionary<String, AnyObject>)["medium"] as! Dictionary<String, AnyObject>)["url"]
                        desiredPlaylistItemDataDict["videoID"] = (playlistSnippetDict["resourceId"] as! Dictionary<String, AnyObject>)["videoId"]
                        desiredPlaylistItemDataDict["date"] = playlistSnippetDict["publishedAt"]
                       
                        // Append the desiredPlaylistItemDataDict dictionary to the videos array.
                        self.videosArray.append(desiredPlaylistItemDataDict as [NSObject : AnyObject])
                        //print("\n\(resultsDict)\n")
                        let resource = Resource(id: desiredPlaylistItemDataDict["videoID"] as! String, title: desiredPlaylistItemDataDict["title"] as! String, url: "https://www.youtube.com/embed/\(desiredPlaylistItemDataDict["videoID"])?rel=0", type: "video", date: desiredPlaylistItemDataDict["date"] as! String, tags: nil)
                        // Reload the tableview.
                        //self.tblVideos.reloadData()
                        self.insertYoutubeFromChannel(resource!, description: desiredPlaylistItemDataDict["description"] as! String, completionHandler: self.finished)
                        
                        
                        
                    }
                    self.pageNum = self.pageNum + 1
                    self.tableView.reloadData()
                    
                    
                    
                    if self.overlayRunning {
                        MRProgressOverlayView.dismissOverlay(for: self.view, animated: true)
                        self.overlayRunning = false
                        
                    }
                    
                    self.tableView.emptyDataSetSource = self
                    self.tableView.emptyDataSetDelegate = self
                    self.tableView.tableFooterView = UIView()
                }
                catch {
                    print("Error loading videos")
                }
                
            }
                
            else {
                print("HTTP Status Code = \(HTTPStatusCode)\n")
                print("Error while loading channel videos: \(error)\n")
            }
            
            
        })
    }
    
    func finished(_ success: Bool) {
        if success == false {
            print("Could not finish loading videos")
        }
        
        if self.overlayRunning {
            MRProgressOverlayView.dismissOverlay(for: self.view, animated: true)
            self.overlayRunning = false
            
        }
        tableView.reloadData()
        
    }
    
    func performGetRequest(_ targetURL: URL!, completion: @escaping (_ data: Data?, _ HTTPStatusCode: Int, _ error: Error?) -> Void) {
        var request = URLRequest(url: targetURL)
        request.httpMethod = "GET"
        
        let sessionConfiguration = URLSessionConfiguration.default
        
        let session = URLSession(configuration: sessionConfiguration)
        let task = session.dataTask(with: request, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) -> Void in
            DispatchQueue.main.async(execute: { () -> Void in
                completion(data, (response as! HTTPURLResponse).statusCode, error)
            })
        })
        
        task.resume()
    }
    
    // MARK: - Table view data source
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
   
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell,forRowAt indexPath: IndexPath) {
        
        //print("Number of videoViews: \(videoViews.count)")
        
        /*let visiblePaths = tableView.indexPathsForVisibleRows
        let lastVisPath = visiblePaths![visiblePaths!.count - 1]
        print("Last visible row: \(lastVisPath.row)")*/
        
        /*verticalContentOffset = tableView.contentOffset.y
        print("Vertical Content offset: \(verticalContentOffset)")*/
        
        
        //Set the height if videoCardHeight hasn't been set yet or there's a smaller card
        if (videoCardHeight - cell.bounds.height > 0 || videoCardHeight == 0) && currentType == .Video{
            videoCardHeight = cell.bounds.height
        }
        
        if !memoryWarning && currentType == .Video && searchActivated == false
            && (videosArray.count < numUploads)
            && tableView.contentOffset.y > (((CGFloat)(videoCards.count-3))*videoCardHeight - videoCardHeight) {
            //verticalContentOffset = tableView.contentOffset.y
            print("Should get videos for channel")
            getVideosForChannel(true)
        }
        
    }
    
    //Return the number of cards depending on the type of resource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchActivated {
            switch (currentType){
            case .Article:
                return filteredArticles.count
            case .Audio:
                return filteredAudioFiles.count
            case .Video:
                return filteredVideos.count
            }
        }
        else {
            switch (currentType){
            case .Article:
                return articles.count
            case .Audio:
                return audioFiles.count
            case .Video:
                return videos.count
            }
        }
        
        
        
    }
    
    //Configures each cell in the table view as a card and sets the UI elements to match with the Resource data
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        //Should be refactored to be more efficient
        //Problem for a later dev
        //if searchActivated {
            switch (currentType){
            case .Article:
                var art: Article
                if searchActivated {
                    art = filteredArticles[indexPath.row]
                }
                else {
                    art = articles[indexPath.row]
                }
                
                let cell = tableView.dequeueReusableCell(withIdentifier: "ArticleTableViewCell", for: indexPath) as! ArticleTableViewCell
                cell.date.text = GlobalUtils.stringFromDate(art.date, format: "MMMM d, yyyy")
                cell.desc.text = art.abstract
                cell.title.text = art.title
                
                //Set up the cell's button for web view controller
                cell.tapAction = {(cell) in
                    let vc = CustomWebViewController()
                    vc.urlString = art.url
                    self.navigationController?.pushViewController(vc, animated: true)
                }

                cell.card.layer.shadowColor = UIColor.black.cgColor
                cell.card.layer.shadowOffset = CGSize(width: 0, height: 1)
                cell.card.layer.shadowOpacity = 0.25
                cell.card.layer.shadowRadius = 2
                
                
                return cell
            case .Video:
                let cell = tableView.dequeueReusableCell(withIdentifier: "VideoTableViewCell", for: indexPath) as! VideoTableViewCell
                
                return cell
            case .Audio:
                let cell = tableView.dequeueReusableCell(withIdentifier: "AudioTableViewCell", for: indexPath) as! AudioTableViewCell
                
                var aud: Audio
                if searchActivated {
                    aud = filteredAudioFiles[indexPath.row]
                }
                else {
                    aud = audioFiles[indexPath.row]
                }
                
                cell.date.text = GlobalUtils.stringFromDate(aud.date, format: "MMMM d, yyyy")
                cell.title.text = aud.title
                cell.audioString = aud.url
                
                cell.prepareAudioFile()
                
                cell.card.layer.shadowColor = UIColor.black.cgColor
                cell.card.layer.shadowOffset = CGSize(width: 0, height: 1)
                cell.card.layer.shadowOpacity = 0.25
                cell.card.layer.shadowRadius = 2
                
                return cell
            }
        //}
        /*else {
            switch (currentType){
            case .Article:
                let cell = tableView.dequeueReusableCell(withIdentifier: "ArticleTableViewCell", for: indexPath) as! ArticleTableViewCell
                let art = articles[indexPath.row]
                cell.date.text = GlobalUtils.stringFromDate(art.date, format: "MMMM d, yyyy")
                cell.desc.text = art.abstract
                cell.title.text = art.title
                
                //Set up the cell's button for web view controller
                cell.tapAction = {(cell) in
                    let vc = CustomWebViewController()
                    vc.urlString = art.url!
                    self.navigationController?.pushViewController(vc, animated: true)
                }
                cell.card.layer.shadowColor = UIColor.black.cgColor
                cell.card.layer.shadowOffset = CGSize(width: 0, height: 1)
                cell.card.layer.shadowOpacity = 0.25
                cell.card.layer.shadowRadius = 2
                
                return cell
            case .Video:
                let cell = tableView.dequeueReusableCell(withIdentifier: "VideoTableViewCell", for: indexPath) as! VideoTableViewCell
                
                return cell
            case .Audio:
                let cell = tableView.dequeueReusableCell(withIdentifier: "AudioTableViewCell", for: indexPath) as! AudioTableViewCell
                
                return cell
            
            }
        }*/
        
        
        
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        selectedRow = indexPath.row
    }
    
    //Sets the constraints for the cards so they float in the middle of the table
    fileprivate func constrainView(_ cardView: CardView, row: Int) {
        cardView.delegate = self
        cardView.translatesAutoresizingMaskIntoConstraints = false
        cardView.horizontallyCenterToSuperView(0)
        
        cardView.constrainTopToSuperView(15)
        cardView.constrainBottomToSuperView(15)
        cardView.constrainRightToSuperView(15)
        cardView.constrainLeftToSuperView(15)
    }
    
    // MARK: Actions
    
    @IBAction func presentSearchModal(_ sender: UIBarButtonItem) {
        
        /*let searchModal = SearchModalViewController()
        searchModal.modalPresentationStyle = UIModalPresentationStyle.Popover
        //self.performSegueWithIdentifier("searchModal", sender: self)
        let popoverMenuViewController = searchModal.popoverPresentationController
        popoverMenuViewController!.permittedArrowDirections = .Unknown
        popoverMenuViewController!.delegate = self
        popoverMenuViewController!.sourceView = self.view
        presentViewController(searchModal,
            animated: true,
            completion: nil)*/
        self.performSegue(withIdentifier: "searchModal", sender: self)
        modalActive = true
        
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.overCurrentContext
    }
    
    //Search modal calls this when "Apply" is tapped
    func applyFilters(_ tags: [ResourceTag], searchText: String?) {
        searchActivated = true
        filteredTags = tags
        modalActive = false
        
        if searchText != nil {
            self.searchPhrase = searchText!
            filterContent(tags, searchText: searchText!)
        }
        else {
            filterContent(tags, searchText: nil)
        }
        
    }
    //Checks if a filtered Resource has a tag the user selected
    func resourceHasTag(_ tags: [String], filteredTags: [ResourceTag]) -> Bool{
        for tag in tags {
            if filteredTags.index(where: {$0.id == tag}) != nil {
                return true
            }
        }
        return false
    }
    
    func resetContent() {
        
    }
    
    func checkTags(_ resTags: [String], filteredTags: [ResourceTag]) -> Bool{
        for tag in resTags {
            for filtTag in filteredTags {
                print("comparing \(tag) to \(filtTag.id)")
                if tag == filtTag.id {
                    return true
                }
            }
        }
        return false
    }
    
    func filterContent(_ tags: [ResourceTag], searchText: String?) {
        
        //Filter by tags first
        let taggedAudio = audioCards.filter { card in
            return checkTags(card.tags!, filteredTags: tags)
        }
        
        let taggedArticles = articleCards.filter { card in
            return checkTags(card.tags!, filteredTags: tags)
        }
        let taggedVideos = videoCards.filter { card in
            if !(card.tags?.isEmpty)! {
                return checkTags(card.tags!, filteredTags: tags)
            }
            return false
        }
        
        if searchText != nil {
            filteredAudioCards = taggedAudio.filter { card in
                return card.title.lowercased().contains(searchText!.lowercased())
            }
            
            filteredArticleCards = taggedArticles.filter { card in
                return card.title.lowercased().contains(searchText!.lowercased())
            }
            filteredVideoCards = taggedVideos.filter { card in
                return card.title.lowercased().contains(searchText!.lowercased())
            }
        }
        else {
            filteredArticleCards = taggedArticles
            filteredAudioCards = taggedAudio
            filteredVideoCards = taggedVideos
        }
        
        tableView.reloadData()
    }
    
    func cardViewRequestedAction(_ cardView: CardView, action: CardViewAction) {
        
        handleCardAction(cardView, action: action)
    }
    
    //reveal controller function for disabling the current view
    func revealController(_ revealController: SWRevealViewController!, willMoveTo position: FrontViewPosition) {
        
        if position == FrontViewPosition.left {
            for view in self.view.subviews {
                view.isUserInteractionEnabled = true
            }
        }
        else if position == FrontViewPosition.right {
            for view in self.view.subviews {
                view.isUserInteractionEnabled = false
            }
        }
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "searchModal" {
            
            let modalVC = segue.destination as! SearchModalViewController
            modalVC.transitioningDelegate = self
            modalVC.preferredContentSize = CGSize(width: UIScreen.main.bounds.width * 0.7, height: UIScreen.main.bounds.height * 0.7)
            modalVC.parentVC = self
            
            
            
            
            modalVC.tags = self.tags
            modalVC.filteredTags = self.tags
            if searchActivated {
                modalVC.filteredTags = self.filteredTags
                modalVC.prevSearchPhrase = self.searchPhrase
                
            }
            dim(.in, alpha: dimLevel, speed: dimSpeed)
            
        }
        else if segue.identifier == "showWebView" {
            let vc = segue.destination as! CustomWebViewController
            
        }
    }
    
    @IBAction func unwindFromSecondary(_ segue: UIStoryboardSegue) {
        dim(.out, speed: dimSpeed)
        modalActive = false
    }
}

//Code that makes the resources screen go dim when Search modal appears
enum Direction { case `in`, out }

protocol Dimmable { }

extension Dimmable where Self: UIViewController {
    
    func dim(_ direction: Direction, color: UIColor = UIColor.black, alpha: CGFloat = 0.0, speed: Double = 0.0) {
        
        switch direction {
        case .in:
            
            // Create and add a dim view
            let dimView = UIView(frame: view.frame)
            dimView.backgroundColor = color
            dimView.alpha = 0.0
            view.addSubview(dimView)
            
            // Deal with Auto Layout
            dimView.translatesAutoresizingMaskIntoConstraints = false
            view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "|[dimView]|", options: [], metrics: nil, views: ["dimView": dimView]))
            view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[dimView]|", options: [], metrics: nil, views: ["dimView": dimView]))
            
            // Animate alpha (the actual "dimming" effect)
            UIView.animate(withDuration: speed, animations: { () -> Void in
                dimView.alpha = alpha
            }) 
            
        case .out:
            UIView.animate(withDuration: speed, animations: { () -> Void in
                self.view.subviews.last?.alpha = alpha ?? 0
                }, completion: { (complete) -> Void in
                    self.view.subviews.last?.removeFromSuperview()
            })
        }
    }
}
