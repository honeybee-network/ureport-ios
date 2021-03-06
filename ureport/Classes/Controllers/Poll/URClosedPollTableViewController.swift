//
//  URPollTableViewController.swift
//  ureport
//
//  Created by Daniel Amaral on 13/08/15.
//  Copyright (c) 2015 ilhasoft. All rights reserved.
//

import UIKit

class URClosedPollTableViewController: UIViewController, URPollManagerDelegate, UITableViewDelegate, UITableViewDataSource, URCurrentPollViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var topView: UIView!
    @IBOutlet weak var contentViewHeight: NSLayoutConstraint!
    @IBOutlet weak var topViewHeight: NSLayoutConstraint!
    
    let pollManager = URPollManager()
    var headerCell:URCurrentPollView!
    var pollList:[URPoll] = []
    
    var responses:[URRulesetResponse] = []
    
    var contact:URContact?
    var currentFlow:URFlowDefinition?
    var currentActionSet:URFlowActionSet?
    var currentRuleset:URFlowRuleset?        
    
    init() {
        super.init(nibName: "URClosedPollTableViewController", bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        setupTableView()
        setupHeaderCell()
        
        self.title = "poll_results".localized
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        URNavigationManager.setupNavigationBarWithCustomColor(URCountryProgramManager.activeCountryProgram()!.themeColor!)
        
        let tracker = GAI.sharedInstance().defaultTracker
        tracker.set(kGAIScreenName, value: "Poll Results List")
        
        let builder = GAIDictionaryBuilder.createScreenView()
        tracker.send(builder.build() as [NSObject : AnyObject])
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        if !URRapidProManager.sendingAnswers {
            loadCurrentFlow()
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.pollList.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(NSStringFromClass(URClosedPollTableViewCell.self), forIndexPath: indexPath) as! URClosedPollTableViewCell
        
        cell.setupCellWithData(self.pollList[indexPath.row])
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let cell = tableView.cellForRowAtIndexPath(indexPath) as? URClosedPollTableViewCell
        self.navigationController?.pushViewController(URPollResultTableViewController(poll: cell!.poll), animated: true)
    }
    
    //MARK: PollManager Delegate
    
    func newPollReceived(poll: URPoll) {
        self.pollList.insert(poll, atIndex: 0)
        self.tableView.reloadData()
        self.fitScrollSize()
    }
    
    func newPollResultReceived(pollResult: URPollResult) {
        
    }
    
    //MARK: URCurrentPollViewDelegate
    
    func onBoundsChanged() {
        reloadCurrentFlowSection()
    }
    
    //MARK: Class Methods
    
    func moveToNextStep() {
        if headerCell.flowRule != nil {
            responses.append(headerCell.getResponse())
            setupNextStep(headerCell.flowRule?.destination)
            
            reloadCurrentFlowSection()
            
        } else {
            UIAlertView(title: nil, message: "answer_poll_choose_error".localized, delegate: self, cancelButtonTitle: "OK").show()
        }
    }
    
    private func setupHeaderCell() {
        headerCell = NSBundle.mainBundle().loadNibNamed("URCurrentPollView", owner: 0, options: nil)[0] as! URCurrentPollView
        headerCell.viewController = self
        headerCell.btNext.addTarget(self, action: "moveToNextStep", forControlEvents: UIControlEvents.TouchUpInside)
    }
    
    private func setupTableView() {
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.backgroundColor = UIColor.clearColor()
        self.tableView.registerNib(UINib(nibName: "URClosedPollTableViewCell", bundle: nil), forCellReuseIdentifier: NSStringFromClass(URClosedPollTableViewCell.self))
        self.tableView.separatorColor = UIColor.clearColor()
        self.tableView.rowHeight = UITableViewAutomaticDimension;
        self.tableView.estimatedRowHeight = 220;
        
        pollManager.delegate = self
        URNavigationManager.setupNavigationBarWithType(.Blue)
        pollManager.getPolls()
    }
    
    private func loadCurrentFlow() {
        URRapidProManager.getContact(URUser.activeUser()!, completion: { (contact) -> Void in
            self.contact = contact
            URRapidProManager.getFlowRuns(contact, completion: { (flowRuns: [URFlowRun]?) -> Void in
                if let flowRuns = flowRuns {
                    if ((!flowRuns.isEmpty) && URFlowManager.isFlowActive(flowRuns[0])) {
                        URRapidProManager.getFlowDefinition(flowRuns[0].flow_uuid, completion: {
                            (flowDefinition: URFlowDefinition) -> Void in
                            self.currentFlow = flowDefinition
                            self.setupNextStep(self.currentFlow!.entry)
                            self.reloadCurrentFlowSection()
                        })
                    }
                }
            })
        })
    }
    
    private func setupNextStep(destination:String?) {
        self.currentActionSet = URFlowManager.getFlowActionSetByUuid(currentFlow!, destination: destination)
        self.currentRuleset = URFlowManager.getRulesetForAction(currentFlow!, actionSet: currentActionSet)
    }
    
    private func reloadCurrentFlowSection() {
        
        headerCell.delegate = self
        
        var currentPollHeight:CGFloat = 0.0
        
        if !URFlowManager.isLastActionSet(currentActionSet) {
            headerCell.setupData(currentFlow!, flowActionSet: currentActionSet!, flowRuleset: currentRuleset!, contact: contact!)
            currentPollHeight = headerCell.getCurrentPollHeight()
            
        }else if currentActionSet == nil {
            
            ProgressHUD.show("message_send_poll".localized)
            
            URRapidProManager.sendRulesetResponses(URUser.activeUser()!, responses: responses, completion: { () -> Void in
                
                dispatch_async(dispatch_get_main_queue()) {
                    self.responses = []
                    ProgressHUD.dismiss()
                }
            })
            
            updateTopViewHeight(0)
            headerCell.removeFromSuperview()
            self.view.endEditing(true)
            
        }else{
            headerCell.setupDataWithNoAnswer(currentFlow, flowActionSet: currentActionSet, flowRuleset: currentRuleset, contact: contact)
            
            currentPollHeight = headerCell.getCurrentPollHeight() - 30
            ProgressHUD.show("message_send_poll".localized)
            
            URRapidProManager.sendRulesetResponses(URUser.activeUser()!, responses: responses, completion: { () -> Void in
                
                dispatch_async(dispatch_get_main_queue()) {
                    self.responses = []
                    ProgressHUD.dismiss()
                }
            })
        }
        
        headerCell.frame = CGRectMake(0, 0, UIScreen.mainScreen().bounds.size.width, currentPollHeight)
        updateTopViewHeight(currentPollHeight)
        fitScrollSize()
    }
    
    private func updateTopViewHeight(newHeight:CGFloat) {
        self.scrollView.contentOffset = CGPointMake(self.scrollView.contentOffset.x, -64)
        topViewHeight.constant = newHeight
        
        UIView.animateWithDuration(0.5) { () -> Void in
            self.view.layoutIfNeeded()
        }
    }
    
    private func fitScrollSize() {
        if topView.subviews.count == 0 {
            topView.addSubview(headerCell)
        }
        
        var scrollViewHeight = topViewHeight.constant
        scrollViewHeight = scrollViewHeight + self.tableView.contentSize.height
        
        self.contentViewHeight.constant = scrollViewHeight
        
        self.scrollView.contentSize = CGSizeMake(UIScreen.mainScreen().bounds.width,scrollViewHeight)
        self.scrollView.contentInset = UIEdgeInsetsMake(64, 0, 49, 0)
        
        self.view.layoutIfNeeded()
    }
    
}
