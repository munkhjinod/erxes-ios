//
//  InboxController.swift
//  Erxes.io
//
//  Created by soyombo bat-erdene on 2/20/18.
//  Copyright © 2018 soyombo bat-erdene. All rights reserved.
//

import UIKit
import Apollo
import SDWebImage
import LiveGQL

public struct FilterOptions {

    public var status: String = ""
    public var channel: ChannelDetail? = nil
    public var brand: BrandDetail? = nil
    public var unassigned: String = ""
    public var participating: String = ""
    public var integrationType: String = ""
    public var tag: TagDetail? = nil
    public var startDate: String = ""
    public var endDate: String = ""
    mutating func removeAll() {
        self = FilterOptions()
    }

    public init() { }
}

class InboxController: InboxControllerUI {
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var total = Int()
    var timer: Timer!
    var topOffset: CGFloat = 0.0
    var conversationLimit = 20
    var loading = false
    var lastPage = false
    var popBack = false
    
    let gql = LiveGQL(socket: Constants.SUBSCRITION_ENDPOINT)

    func configLive() {
        gql.delegate = self
    }

    func subscribe() {
        gql.subscribe(graphql: "subscription {conversationClientMessageInserted {_id,conversationId}}", variables: nil, operationName: nil, identifier: "conversationClientMessageInserted")
    }

    var conversations = [ObjectDetail]() {
        didSet {

        }
    }

    var lastItem = [ObjectDetail]() {
        didSet {

            let index = lastItem[0].findIndex(from: self.conversations)
      
            self.conversations.remove(at: index)
            self.conversations.insert(lastItem[0], at: 0)

            let updateIndexPath1 = IndexPath(row: index, section: 0)
            let updateIndexPath2 = IndexPath(row: 0, section: 0)

            //
            self.tableView.beginUpdates()
            self.tableView.reloadRows(at: [updateIndexPath1, updateIndexPath2], with: UITableViewRowAnimation.fade)
            self.tableView.endUpdates()
        }
    }

    var filterView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()

    var filterController = FilterController()

    @objc func navigateFilter() {

        filterController.delegate = self
        if self.options != nil {
            filterController.filterOptions = self.options!
        }
        filterController.modalPresentationStyle = .overFullScreen
        self.present(filterController, animated: true) {

        }
    }

    public var options: FilterOptions? = nil

    func configureViews() {
        filterButton.addTarget(self, action: #selector(navigateFilter), for: .touchUpInside)
        tableView.delegate = self
        tableView.dataSource = self
        refresher.addTarget(self, action: #selector(refresh), for: .valueChanged)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let currentUser = ErxesUser.sharedUserInfo()
        topOffset = UIApplication.shared.statusBarFrame.height + (self.navigationController?.navigationBar.frame.size.height)! + 3
        self.title = "Inbox"
        self.view.backgroundColor = UIColor.INBOX_BG_COLOR
        self.configureViews()
        configLive()
        self.subscribe()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if popBack {
            self.getInbox()
            popBack = false
        }
    }
    
    func presentViewControllerAsPopover(viewController: UIViewController, from: UIView) {
        if let presentedVC = self.presentedViewController {
            if presentedVC.nibName == viewController.nibName {
                // The view is already being presented
                return
            }
        }
        // Specify presentation style first (makes the popoverPresentationController property available)
        viewController.modalPresentationStyle = .popover
        let viewPresentationController = viewController.popoverPresentationController
        if let presentationController = viewPresentationController {
            presentationController.delegate = self
            presentationController.permittedArrowDirections = [.down, .up]
            presentationController.sourceView = from
            presentationController.sourceRect = from.bounds
        }
        viewController.preferredContentSize = CGSize(width: Constants.SCREEN_WIDTH, height: 300)

        self.present(viewController, animated: true, completion: nil)
    }

    @objc func refresh() {
        lastPage = false
        getInbox(limit: 20)
    }
    
    @objc func getInbox(limit: Int = 20) {
        
        if loading {
            return
        }
        loading = true
        
        if self.timer != nil {
            self.timer.invalidate()
        }
        let query = ObjectsQuery()

        if options != nil {
            query.brandId = options?.brand?.id
            if options?.unassigned.count != 0 {
                query.unassigned = "true"
            }
            if options?.participating.count != 0 {
                query.participating = "true"
            }
            query.channelId = options?.channel?.id
            query.status = options?.status
            query.integrationType = options?.integrationType
            if options?.startDate.count != 0 {
                query.startDate = (options?.startDate)! + " 00:00"
            }

            if options?.endDate.count != 0 {
                query.endDate = (options?.endDate)! + " 00:00"
            }
            query.tag = options?.tag?.id

        }
        query.limit = limit

        appnet.fetch(query: query, cachePolicy: CachePolicy.fetchIgnoringCacheData) { [weak self] result, error in
            
            self?.refresher.endRefreshing()
            if !(self?.loading)! {
                return
            }
            self?.loading = false
            
            if let error = error {

                let alert = FailureAlert(message: error.localizedDescription)
                alert.show(animated: true)
                return
            }
            if let err = result?.errors {
                let alert = FailureAlert(message: err[0].localizedDescription)
                alert.show(animated: true)
            }
            if result?.data != nil {
                if let allConversations = result?.data?.conversations {
                  
                    if allConversations.count < self?.conversationLimit ?? 0 {
                        self?.lastPage = true
                    }
                    
                    if allConversations.count == 0 {
                        self?.conversations.removeAll()
                        self?.tableView.reloadData()
                        self?.tableView.isHidden = true
                        self?.robotView.isHidden = false
                    } else {
                        self?.tableView.isHidden = false
                        self?.robotView.isHidden = true
                        self?.conversations = allConversations.map { ($0?.fragments.objectDetail)! }
                    }
                    self?.tableView.reloadData()
                }
            }
        }
    }

    func getUnreadCount() {
        let query = UnreadCountQuery()
        appnet.fetch(query: query, cachePolicy: CachePolicy.fetchIgnoringCacheData) { [weak self] result, error in
            if let error = error {
    
                let alert = FailureAlert(message: error.localizedDescription)
                alert.show(animated: true)
                return
            }
            if let err = result?.errors {
                let alert = FailureAlert(message: err[0].localizedDescription)
                alert.show(animated: true)
            }
            if result?.data != nil {
                if let count = result?.data?.conversationsTotalUnreadCount {
              
                    if count != 0 {
                        self?.tabBarItem.badgeColor = .red
                        self?.tabBarItem.badgeValue = String(format: "%i", count)
                    } else {
                        self?.tabBarItem.badgeValue = nil
                    }
                }
            }
        }
    }

    func getTimeComponentString(olderDate older: Date, newerDate newer: Date) -> (String?) {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .full

        let componentsLeftTime = Calendar.current.dateComponents([.minute, .hour, .day, .month, .weekOfMonth, .year], from: older, to: newer)

        let year = componentsLeftTime.year ?? 0
        if year > 0 {
            formatter.allowedUnits = [.year]
            return formatter.string(from: older, to: newer)
        }

        let month = componentsLeftTime.month ?? 0
        if month > 0 {
            formatter.allowedUnits = [.month]
            return formatter.string(from: older, to: newer)
        }

        let weekOfMonth = componentsLeftTime.weekOfMonth ?? 0
        if weekOfMonth > 0 {
            formatter.allowedUnits = [.weekOfMonth]
            return formatter.string(from: older, to: newer)
        }

        let day = componentsLeftTime.day ?? 0
        if day > 0 {
            formatter.allowedUnits = [.day]
            return formatter.string(from: older, to: newer)
        }

        let hour = componentsLeftTime.hour ?? 0
        if hour > 0 {
            formatter.allowedUnits = [.hour]
            return formatter.string(from: older, to: newer)
        }

        let minute = componentsLeftTime.minute ?? 0
        if minute > 0 {
            formatter.allowedUnits = [.minute]
            return formatter.string(from: older, to: newer) ?? ""
        }

        return nil
    }
}

extension InboxController {
    
    func changeStatus(id:String, status:String) {
        let mutation = ConversationsChangeStatusMutation(_ids: [id], status: status)
        appnet.perform(mutation: mutation) { [weak self] result, error in
            if let error = error {
                print(error.localizedDescription)
                let alert = FailureAlert(message: error.localizedDescription)
                alert.show(animated: true)
                //self?.hideLoader()
                return
            }
            if let err = result?.errors {
                let alert = FailureAlert(message: err[0].localizedDescription)
                alert.show(animated: true)
                //self?.hideLoader()
            }
            if result?.data != nil {
                self?.getInbox(limit: (self?.conversationLimit)!)
            }
        }
    }
}
