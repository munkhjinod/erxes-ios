//
//  ContactController.swift
//  NMG.CRM
//
//  Created by Soyombo bat-erdene on 6/13/18.
//  Copyright © 2018 soyombo bat-erdene. All rights reserved.
//

import UIKit
import Apollo


class ContactController: UIViewController {


    
    let arr = ["Customers","Companies"]
    var loader: ErxesLoader = {
        let loader = ErxesLoader(frame: CGRect(x: Constants.SCREEN_WIDTH/2-25, y: Constants.SCREEN_HEIGHT/2-25, width: 50, height: 50))
        loader.lineWidth = 3
        return loader
    }()
    var isCustomer:Bool = true
    var customersLimit = 20
    var companiesLimit = 20
    var customers = [CustomerList]() {
        didSet {
            tableView.reloadData()
        }
    }
    
    var companies = [CompanyList]() {
        didSet {
            tableView.reloadData()
        }
    }
   

    var customerAddButton:UIButton = {
       let button = UIButton()
        let image = UIImage.erxes(with: .adduser, textColor: .white)
        button.setBackgroundImage(image, for: .normal)
        button.tintColor = UIColor.white
        button.addTarget(self, action: #selector(addAction(sender:)), for: .touchUpInside)
        return button
    }()
    
    var companyAddButton:UIButton = {
        let button = UIButton()
        let image = #imageLiteral(resourceName: "ic_addCompany")
        button.setBackgroundImage(image, for: .normal)
        button.tintColor = UIColor.white
        button.addTarget(self, action: #selector(addAction(sender:)), for: .touchUpInside)
        return button
    }()
    

    
    var segmentedControl: UISegmentedControl = {
        let items = ["Customer","Company"]
        let control = UISegmentedControl(items: items)
        control.frame = CGRect(x: 0, y: 0, width: 200, height: 23)
        control.layer.cornerRadius = 5.0
        control.tintColor = UIColor.init(hexString: "4e25a5")
        control.backgroundColor = UIColor.init(hexString: "421f8b")
        let attributes = [
            NSAttributedStringKey.foregroundColor: UIColor.white,
            NSAttributedStringKey.font: UIFont.fontWith(type: .comfortaa, size: 15)
        ]

        control.setTitleTextAttributes(attributes, for: .normal)
        control.setTitleTextAttributes(attributes, for: .selected)
        control.selectedSegmentIndex = 0
       
        
        return control
    }()
    
    var tableView: UITableView = {
        let tableView = UITableView()
        tableView.register(ContactCell.self, forCellReuseIdentifier: "ContactCell")
        tableView.rowHeight = 50
        tableView.tableFooterView = UIView()
        tableView.backgroundColor = .clear
        tableView.separatorColor = UIColor.ERXES_COLOR

        return tableView
    }()
    
    @objc func toggleSegmentedControl(sender:UISegmentedControl){
        
        let leftItem: UIBarButtonItem = {
            let barButtonItem = UIBarButtonItem()
            return barButtonItem
        }()
        
        if sender.selectedSegmentIndex == 0 {
            isCustomer = true
            customerAddButton.addTarget(self, action: #selector(addAction(sender:)), for: .touchUpInside)
            leftItem.customView = customerAddButton
            self.getCustomers()
        }else{
            companyAddButton.addTarget(self, action: #selector(addAction(sender:)), for: .touchUpInside)
            leftItem.customView = companyAddButton
            isCustomer = false
            self.getCompanies()
        }
        self.navigationItem.leftBarButtonItem? = leftItem
    }
    

    func configureViews(){
        
        let rightItem: UIBarButtonItem = {
            var rightImage = #imageLiteral(resourceName: "ic_filter")
   
            rightImage = rightImage.withRenderingMode(.alwaysTemplate)
            let barButtomItem = UIBarButtonItem()
            let button = UIButton()
            button.setBackgroundImage(rightImage, for: .normal)
            button.tintColor = UIColor.white
            button.addTarget(self, action: #selector(changeEditMode(sender:)), for: .touchUpInside)
            barButtomItem.customView = button
            return barButtomItem
        }()
        let leftItem: UIBarButtonItem = {
            let barButtonItem = UIBarButtonItem()
            customerAddButton.addTarget(self, action: #selector(addAction(sender:)), for: .touchUpInside)
            barButtonItem.customView = self.customerAddButton
            return barButtonItem
        }()

       
        self.navigationItem.leftBarButtonItem = leftItem
        self.navigationItem.rightBarButtonItem = rightItem
        segmentedControl.addTarget(self, action: #selector(toggleSegmentedControl(sender:)), for: .valueChanged)
        self.navigationItem.titleView = segmentedControl
    
        tableView.delegate = self
        tableView.dataSource = self
        self.view.addSubview(tableView)
        self.view.addSubview(loader)
    }
    
    func isEditing() {
        
    }
    
   
    
    @objc func changeEditMode(sender:UIButton) {
        sender.isSelected = !sender.isSelected
        tableView.isEditing = sender.isSelected
    }
    
    @objc func addAction(sender:UIButton) {
        print("add click")
        if isCustomer{
            navigate(.customerProfile(_id: nil))
        }else{
            navigate(.companyProfile(id:nil))
        }
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Contacts"
        self.view.backgroundColor = UIColor.white
        self.configureViews()
//        self.getCustomers()
    }
    
    override func viewWillAppear(_ animated: Bool) {
     
        if isCustomer{
            
            getCustomers()
        }else{
         
           
            getCompanies()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
 
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        
        tableView.snp.makeConstraints { (make) in
            make.left.equalTo(self.view.snp.left).offset(16)
            make.right.equalTo(self.view.snp.right).inset(16)
            make.top.equalTo(self.topLayoutGuide.snp.bottom)
            make.bottom.equalTo(self.bottomLayoutGuide.snp.top)
        }
        
//        loader.snp.makeConstraints { (make) in
//            make.width.height.equalTo(50)
//            make.center.equalTo(self.view.snp.center)
//        }

    }
    
    func getCompanies(limit:Int = 20){
        loader.startAnimating()
        let query = CompaniesQuery()
        query.perPage = limit
        
        appnet.fetch(query: query, cachePolicy: .fetchIgnoringCacheData) { [weak self] result, error in
            if let error = error {
                print(error.localizedDescription)
                let alert = FailureAlert(message: error.localizedDescription)
                alert.show(animated: true)
                self?.loader.stopAnimating()
                return
            }
            
            if let err = result?.errors {
                let alert = FailureAlert(message: err[0].localizedDescription)
                alert.show(animated: true)
                self?.loader.stopAnimating()
            }
            
            if result?.data != nil {
                if let allCompanies = result?.data?.companies {
                    self?.companies = allCompanies.map { ($0?.fragments.companyList)! }
                self?.loader.stopAnimating()
                }
            }
        }
    }
    
    func getCustomers(limit: Int = 20) {
        loader.startAnimating()
        let query = CustomersQuery()
        query.perPage = limit
        appnet.fetch(query: query, cachePolicy: .fetchIgnoringCacheData) { [weak self] result, error in
            if let error = error {
                print(error.localizedDescription)
                let alert = FailureAlert(message: error.localizedDescription)
                alert.show(animated: true)
                self?.loader.stopAnimating()
                return
            }
            
            if let err = result?.errors {
                let alert = FailureAlert(message: err[0].localizedDescription)
                alert.show(animated: true)
                self?.loader.stopAnimating()
            }
            
            if result?.data != nil {
                if let allCustomers = result?.data?.customers {
                    self?.customers = allCustomers.map { ($0!.fragments.customerList) }
//                    self?.customers = allCustomers.list.map {($0.fra)}
                self?.loader.stopAnimating()
                    
                }
            }
        }
    }
    
    func deleteCustomer(index:Int) {
        let customer = customers[index]
        mutateDeleteCustomer(customerIds: [customer.id])
    }
    
    func mutateDeleteCustomer(customerIds:[String]) {
        let mutation = CustomersRemoveMutation(customerIds: customerIds)
        
        appnet.perform(mutation: mutation) { [weak self] result, error in
            self?.getCustomers()
        }
    }
    
    func deleteCompany(index:Int) {
        let company = companies[index]
        mutateDeleteCompany(companyIds: [company.id])
    }

    func mutateDeleteCompany(companyIds:[String]) {
        let mutation = CompaniesRemoveMutation(companyIds: companyIds)
        
        appnet.perform(mutation: mutation) { [weak self] result, error in
            self?.getCompanies()
        }
    }
}

extension ContactController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "ContactCell", for: indexPath) as? ContactCell
        if cell == nil {
            cell = ContactCell.init(style: .default, reuseIdentifier: "ContactCell")
        }
        cell?.topLabel.text = ""
        cell?.bottomLabel.text = ""
        cell?.icon.image = nil
        if isCustomer{
            let customer = customers[indexPath.row]
            cell?.icon.image = #imageLiteral(resourceName: "ic_customer").tint(with: UIColor.ERXES_COLOR)
    
            if customer.firstName != nil && customer.lastName != nil{
                cell?.topLabel.text = customer.firstName! + " " + customer.lastName!
            }else if customer.firstName != nil && customer.lastName == nil{
                cell?.topLabel.text = customer.firstName
            }else if customer.firstName == nil && customer.lastName != nil {
                cell?.topLabel.text = customer.lastName
            }else{
                cell?.topLabel.text = "Unnamed"
            }
            if customer.email != nil {
                cell?.bottomLabel.text = customer.email
            }else if customer.phone != nil {
                cell?.bottomLabel.text = customer.phone
            }
            
        }else{
            cell?.icon.image = #imageLiteral(resourceName: "ic_company").tint(with: UIColor.ERXES_COLOR)
            let company = companies[indexPath.row]
            if company.primaryName != nil {
                cell?.topLabel.text = company.primaryName
            }
            if company.plan != nil {
                cell?.bottomLabel.text = company.plan
            }
        }
        
        return cell!
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            if isCustomer{
                deleteCustomer(index: indexPath.row)
            }else{
                deleteCompany(index: indexPath.row)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if isCustomer{
            let customer = customers[indexPath.row]
            navigate(.customerProfile(_id: customer.id))
        }else{
            let company = companies[indexPath.row]
            navigate(.companyProfile(id: company.id))
        }
       
    }
}

extension ContactController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isCustomer{
            return customers.count
        }else{
            return companies.count
        }
    }
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        //        self.timer.invalidate()
        let currentOffset = scrollView.contentOffset.y
        let maximumOffset = scrollView.contentSize.height - scrollView.frame.size.height
        
        if maximumOffset - currentOffset <= 0.0 {
            if isCustomer{
                customersLimit = customersLimit + 20
                self.getCustomers(limit: customersLimit)
            }else{
                companiesLimit = companiesLimit + 20
                self.getCompanies(limit: companiesLimit)
            }
        }
    }
}



