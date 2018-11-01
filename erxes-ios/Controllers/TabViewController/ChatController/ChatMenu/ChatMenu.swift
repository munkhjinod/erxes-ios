//
//  ChatMenu.swift
//  erxes-ios
//
//  Created by alternate on 11/1/18.
//  Copyright © 2018 soyombo bat-erdene. All rights reserved.
//

import Foundation
import UIKit
import Apollo

class ChatMenu:ViewController {
    
    var sections = ["Actions","Assign"]
    var users = [UserData]() {
        didSet{
        }
    }
    
    var conversationId = ""
    
    var filteredUsers = [UserData]() {
        didSet{
            tableView.reloadData()
        }
    }
    
    let tableView:UITableView = {
        let tv = UITableView()
        tv.register(MyTableViewCell.self, forCellReuseIdentifier: "userCell")
        tv.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tv.register(InputCell.self, forCellReuseIdentifier: InputCell.ID)
        return tv
    }()
    
    override func prepareView() {
        self.view.backgroundColor = .white
        self.view.addSubview(tableView)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.reloadData()
        queryUsers()
    }
    
    override func layoutView() {
        tableView.snp.makeConstraints{ (make) in
            make.edges.equalToSuperview()
        }
    }
    
    func filterUsers(_ value:String) {
        filteredUsers = users.filter{$0.username?.lowercased().hasPrefix(value.lowercased()) ?? false}
    }
    
    @objc func inputChanged(_ sender:UITextField) {
        
        if let value = sender.text,value.count > 0 {
            filterUsers(value)
        } else {
            self.filteredUsers = self.users
        }
    }
}

extension ChatMenu:UITableViewDataSource,UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if section == 0 {
            return 4
        }
        
        if section == 1 {
            return filteredUsers.count
        }
        
        return 0
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 40
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let row = indexPath.row
        let section = indexPath.section
//        var cell = MyTableViewCell(style: .default, reuseIdentifier: "cell") as UITableViewCell
        var cell:UITableViewCell
        
        if section == 0 {
            
            if row == 3 {
                let inputCell = tableView.dequeueReusableCell(withIdentifier: InputCell.ID, for: indexPath) as? InputCell
                inputCell?.input.addTarget(self, action: #selector(inputChanged), for: .editingChanged)
                return inputCell!
            }
            
            cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
            
            if row == 0 {
                
                cell.imageView?.image = UIImage.erxes(with: .checked, textColor: .black)
                cell.textLabel?.text = "Resolve"
            }
            
            if row == 1 {
                cell.imageView?.image = UIImage.erxes(with: .user, textColor: .black)
                cell.textLabel?.text = "Customer Profile"
            }
            
            if row == 2 {
                cell.imageView?.image = UIImage.erxes(with: .followers, textColor: .black)
                cell.textLabel?.text = "Assign"
            }
            
            return cell
        } else {
            cell = tableView.dequeueReusableCell(withIdentifier: "userCell", for: indexPath)
            cell.textLabel?.text = filteredUsers[row].username
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let section = indexPath.section
        let row = indexPath.row
        
        if section == 0 {
            if row == 0 {
                self.presentAlert(title: "Erxes", msg: "Are you sure you want to resolve this conversation?") {
                    self.changeStatus(id: self.conversationId, status: "closed")
                }
            }
            
            if row == 1 {
                
            }
    
        } else {
            let user = filteredUsers[row]
            self.presentAlert(title: "Erxes", msg: "Assign to " + user.username! + "?") {
                self.assignUser(user: user, conversationId: self.conversationId)
            }
        }
        
    }
}
