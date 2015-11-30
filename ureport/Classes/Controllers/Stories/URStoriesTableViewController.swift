//
//  URStoriesTableViewController.swift
//  ureport
//
//  Created by Daniel Amaral on 14/07/15.
//  Copyright (c) 2015 ilhasoft. All rights reserved.
//

import UIKit
import Alamofire
import AlamofireObjectMapper

class URStoriesTableViewController: UITableViewController, URStoryManagerDelegate, URStoriesTableViewCellDelegate {
    
    let imgViewHistoryHeight:CGFloat = 188.0
    let fullHeightTableViewCell:CGFloat = 471
    let contentViewBottom = 2
    let storyManager = URStoryManager()
    var storyList:[URStory] = []
    var newsList:[URNews] = []
    var filterStoriesToModerate:Bool!
    var modalProfileViewController:URModalProfileViewController!
    var index = 1

    init (filterStoriesToModerate:Bool) {
        self.storyList.removeAll()
        self.filterStoriesToModerate = filterStoriesToModerate
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()        
        reloadDataWithStories()
        
        if filterStoriesToModerate == false {
            loadNews()
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        ProgressHUD.dismiss()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        URNavigationManager.setupNavigationBarWithCustomColor(URCountryProgramManager.activeCountryProgram()!.themeColor!)        
    }
    
    //MARK: URStoriesTableViewCellDelegate
    
    func openProfile(user: URUser) {
        self.modalProfileViewController = URModalProfileViewController(user: user)
        self.modalProfileViewController.modalPresentationStyle = UIModalPresentationStyle.OverCurrentContext
        self.navigationController!.presentViewController(modalProfileViewController, animated: true) { () -> Void in
            UIView.animateWithDuration(0.3) { () -> Void in
                self.modalProfileViewController.view.backgroundColor  = UIColor.blackColor().colorWithAlphaComponent(0.5)
            }
        }
        
    }
    
    //MARK: MenuDelegateMethods
    
    func countryProgramDidChanged(countryProgram: URCountryProgram) {
        storyList.removeAll()
        storyManager.getStories(false)
    }
    
    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.storyList.count + self.newsList.count
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        
        if indexPath.row < self.storyList.count {
            let story = storyList[indexPath.row]
            
            if story.cover != nil && story.cover.url != nil {
                return 471
            }else {
                return 471 - imgViewHistoryHeight
            }
        }else {
            return 245
        }
        
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        if indexPath.row < self.storyList.count {
        
            let cell = tableView.dequeueReusableCellWithIdentifier(NSStringFromClass(URStoriesTableViewCell.self), forIndexPath: indexPath) as! URStoriesTableViewCell
            
            let story = storyList[indexPath.row]
            cell.delegate = self
            cell.viewController = self
            cell.setupCellWith(story,moderateUserMode: self.filterStoriesToModerate)
            return cell
        }else {
            let cell = tableView.dequeueReusableCellWithIdentifier(NSStringFromClass(URNewsTableViewCell.self), forIndexPath: indexPath) as! URNewsTableViewCell
            let news = newsList[indexPath.row - self.storyList.count]
            cell.setupCellWith(news)
            return cell
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let cell = tableView.cellForRowAtIndexPath(indexPath)
        
        if cell is URStoriesTableViewCell {
            if let _ = URUser.activeUser() {
                self.navigationController?.pushViewController(URStoryContributionViewController(story: (cell as! URStoriesTableViewCell).story), animated: true)
            }else {
                URLoginAlertController.show(self)
            }
        }else if cell is URNewsTableViewCell {
            self.navigationController?.pushViewController(URNewsDetailViewController(news:(cell as! URNewsTableViewCell).news),animated: true)
        }
        
    }
    
    //MARK: Class Methods
    
    func loadNews() {
        
        if let org = URCountryProgramManager.activeCountryProgram()!.org {
            let url = "\(URConstant.RapidPro.API_NEWS)\(org)"
            print(url)
            Alamofire.request(.GET, url, headers: nil).responseObject({ (response:URAPIResponse<URNews>?, error:ErrorType?) -> Void in
                if let response = response {
                    self.newsList = response.results
                    self.tableView.reloadData()
                }
            })
            
        }
        
    }
    
    func reloadDataWithStories() {
        ProgressHUD.show(nil)
        storyManager.delegate = self
        storyList.removeAll()
        storyManager.getStories(self.filterStoriesToModerate)        
    }
    
    private func setupTableView() {
        self.tableView.delegate = self
        self.tableView.backgroundColor = URConstant.Color.WINDOW_BACKGROUND
        self.tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 49, right: 0)
        
        self.tableView.registerNib(UINib(nibName: "URStoriesTableViewCell", bundle: nil), forCellReuseIdentifier: NSStringFromClass(URStoriesTableViewCell.self))
        self.tableView.registerNib(UINib(nibName: "URNewsTableViewCell", bundle: nil), forCellReuseIdentifier: NSStringFromClass(URNewsTableViewCell.self))
        self.tableView.separatorColor = UIColor.clearColor()
    }
    
    //MARK: StoryManagerDelegate
    
    func removeCell(cell: URStoriesTableViewCell) {
        let indexPath = self.tableView.indexPathForCell(cell)!
        self.storyList.removeAtIndex(indexPath.row)
        self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Fade)
    }
    
    func newStoryReceived(story: URStory) {
        ProgressHUD.dismiss()
        storyList.insert(story, atIndex: 0)
        self.tableView.insertRowsAtIndexPaths([NSIndexPath(forRow: storyList.count - index, inSection: 0)], withRowAnimation: UITableViewRowAnimation.Fade)
        index++
    }
    
}
