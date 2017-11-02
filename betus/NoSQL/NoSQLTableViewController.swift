//
//  NoSQLTableViewController.swift
//  MySampleApp
//
//
// Copyright 2017 Amazon.com, Inc. or its affiliates (Amazon). All Rights Reserved.
//
// Code generated by AWS Mobile Hub. Amazon gives unlimited permission to 
// copy, distribute and modify it.
//
// Source code generated from template: aws-my-sample-app-ios-swift v0.19
//

import Foundation
import UIKit
import AWSDynamoDB

class NoSQLTableViewController: UITableViewController {
    
    fileprivate var sectionTitles: [String] = []
    var table: Table?
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = table?.tableDisplayName
        
        // Activity indicator for displaying activity in progress
        activityIndicator.center = view.center
        view.addSubview(activityIndicator)
        
        tableView.estimatedRowHeight = tableView.rowHeight
        tableView.rowHeight = UITableViewAutomaticDimension
        
        sectionTitles.append("Get")
        
        table!.indexes.forEach { (secondaryIndex: Index) in
            if let secondaryIndexName = secondaryIndex.indexName {
                sectionTitles.append("Secondary index queries (\(secondaryIndexName))")
            } else {
                sectionTitles.append("Primary Index Queries")
            }
        }
        
        sectionTitles.append("Scan")
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.isToolbarHidden = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.isToolbarHidden = true
    }
    
    // MARK: - Table View data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return sectionTitles.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Get item
        if (section == 0) {
            return 1
        }
        
        // Queries
        if (section >= 1 && section < table!.indexes.count + 1) {
            let index: Index = table!.indexes[section-1]
            return index.supportedOperations().count
        }
        
        // Scan
        if (table?.scanWithFilterDescription?() != nil) {
            return 2
        }
        return 1
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sectionTitles[section]
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if let headerFooterView = view as? UITableViewHeaderFooterView {            
            headerFooterView.textLabel?.text = sectionTitles[section]
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: NoSQLTableCell = tableView.dequeueReusableCell(withIdentifier: "NoSQLTableCell", for: indexPath) as! NoSQLTableCell
        
        // Get Item
        if (indexPath.section == 0) {
            cell.queryType = GetItem
            cell.queryTypeLabel.text = "Get Item"
            cell.queryDescriptionLabel.text = table?.getItemDescription?()
            return cell
        }
        
        // Queries
        if (indexPath.section >= 1 && indexPath.section < table!.indexes.count + 1) {
            let index = table!.indexes[indexPath.section - 1]
            cell.queryType = index.supportedOperations()[indexPath.row]
            
            if (cell.queryType! == QueryWithPartitionKey) {
                cell.queryTypeLabel.text = "Query by Partition Key"
                cell.queryDescriptionLabel.text = index.queryWithPartitionKeyDescription?()
                return cell
            }
            
            if (cell.queryType! == QueryWithPartitionKeyAndFilter) {
                cell.queryTypeLabel.text = "Query by Partition Key and Filter"
                cell.queryDescriptionLabel.text = index.queryWithPartitionKeyAndFilterDescription?()
                return cell
            }
            
            if (cell.queryType! == QueryWithPartitionKeyAndSortKey) {
                cell.queryTypeLabel.text = "Query by Partition Key and Sort Condition"
                cell.queryDescriptionLabel.text = index.queryWithPartitionKeyAndSortKeyDescription?()
                return cell
            }
            
            if (cell.queryType == QueryWithPartitionKeyAndSortKeyAndFilter) {
                cell.queryTypeLabel.text = "Query by Partition Key, Sort Condition, and Filter"
                cell.queryDescriptionLabel.text = index.queryWithPartitionKeyAndSortKeyAndFilterDescription?()
                return cell
            }
        }
        
        // Scan
        if (indexPath.row == 0) {
            cell.queryType = Scan
            cell.queryTypeLabel.text = "Scan"
            cell.queryDescriptionLabel.text = table?.scanDescription?()
            
        } else if (indexPath.row == 1) {
            cell.queryType = ScanWithFilter
            cell.queryTypeLabel.text = "Scan With Filter"
            cell.queryDescriptionLabel.text = table?.scanWithFilterDescription?()
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let showQueryResultSeque = "NoSQLShowQueryResultSegue"
        let cell = tableView.cellForRow(at: indexPath) as! NoSQLTableCell
        activityIndicator.startAnimating()
        
        // Get item
        if indexPath.section == 0 {
            table?.getItemWithCompletionHandler?({(response: AWSDynamoDBObjectModel?, error: NSError?) -> Void in
                self.activityIndicator.stopAnimating()
                if let error = error {
                    self.showAlertWithTitle("Error", message: "Failed to load an item. \(error.localizedDescription)")
                }
                else if let response = response {
                    self.performSegue(withIdentifier: showQueryResultSeque, sender: [response])
                }
                else {
                    self.showAlertWithTitle("Not Found", message: "No items match your criteria. Insert more sample data and try again.")
                }
                
                tableView.deselectRow(at: indexPath, animated: true)
            })
            return
        }
        
        let completionHandler = {(response: AWSDynamoDBPaginatedOutput?, error: NSError?) -> Void in
            self.activityIndicator.stopAnimating()
            if let error = error {
                var errorMessage = "Failed to retrieve items. \(error.localizedDescription)"
                if (error.domain == AWSServiceErrorDomain && error.code == AWSServiceErrorType.accessDeniedException.rawValue) {
                    errorMessage = "Access denied. You are not allowed to perform this operation."
                }
                self.showAlertWithTitle("Error", message: errorMessage)
            }
            else if response!.items.count == 0 {
                self.showAlertWithTitle("Not Found", message: "No items match your criteria. Insert more sample data and try again.")
            }
            else {
                self.performSegue(withIdentifier: showQueryResultSeque, sender: response)
            }
            
            tableView.deselectRow(at: indexPath, animated: true)
        }
        
        // Queries
        if indexPath.section >= 1 && indexPath.section < table!.indexes.count + 1 {
            let index = table!.indexes[indexPath.section - 1]
            cell.queryType = index.supportedOperations()[indexPath.row]
            if (cell.queryType == QueryWithPartitionKey) {
                index.queryWithPartitionKeyWithCompletionHandler?(completionHandler)
                return
            }
            if (cell.queryType == QueryWithPartitionKeyAndFilter) {
                index.queryWithPartitionKeyAndFilterWithCompletionHandler?(completionHandler)
                return
            }
            if (cell.queryType == QueryWithPartitionKeyAndSortKey) {
                index.queryWithPartitionKeyAndSortKeyWithCompletionHandler?(completionHandler)
                return
            }
            if (cell.queryType == QueryWithPartitionKeyAndSortKeyAndFilter) {
                index.queryWithPartitionKeyAndSortKeyAndFilterWithCompletionHandler?(completionHandler)
                return
            }
        }
        
        let scanWarningMessage = "This operation scans the entire table and should not generally be used in a production app."
        if indexPath.row == 0 {
            let alartController: UIAlertController = UIAlertController(title: "WARNING: Scan is Expensive", message: scanWarningMessage, preferredStyle: .alert)
            let proceedAction: UIAlertAction = UIAlertAction(title: "OK", style: .default, handler: {(action: UIAlertAction) -> Void in
                self.table?.scanWithCompletionHandler?(completionHandler)
            })
            alartController.addAction(proceedAction)
            self.present(alartController, animated: true, completion: nil)
        }
        else if indexPath.row == 1 {
            let alartController: UIAlertController = UIAlertController(title: "WARNING: Scan is Expensive", message: scanWarningMessage, preferredStyle: .alert)
            let proceedAction: UIAlertAction = UIAlertAction(title: "OK", style: .default, handler: {(action: UIAlertAction) -> Void in
                self.table?.scanWithFilterWithCompletionHandler?(completionHandler)
            })
            alartController.addAction(proceedAction)
            self.present(alartController, animated: true, completion: nil)
        }

    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let indexPath = tableView.indexPathForSelectedRow
        let cell = tableView.cellForRow(at: indexPath!) as! NoSQLTableCell
        
        if let queryResultViewController = segue.destination as? NoSQLQueryResultViewController {
            queryResultViewController.queryType = cell.queryTypeLabel.text!
            queryResultViewController.queryDescription = cell.queryDescriptionLabel.text!
            queryResultViewController.table = self.table
            if let sender = sender as? AWSDynamoDBPaginatedOutput {
                let paginatedOutput: AWSDynamoDBPaginatedOutput = sender
                queryResultViewController.results = paginatedOutput.items
                queryResultViewController.paginatedOutput = paginatedOutput
            }
            else {
                queryResultViewController.results = (sender as? [AWSDynamoDBObjectModel])
            }
        }
    }
    
    // MARK: - User Action Methods
    
    @IBAction func insertSampleData(_ sender: AnyObject) {
        activityIndicator.startAnimating()
        table?.insertSampleDataWithCompletionHandler?({(errors: [NSError]?) -> Void in
            self.activityIndicator.stopAnimating()
            var message: String = "20 sample items were added to your table."
            if errors != nil {
                message = "Failed to insert sample items to your table."
            }
            let alartController = UIAlertController(title: nil, message: message, preferredStyle: .alert)
            let dismissAction = UIAlertAction(title: "Dismiss", style: .cancel, handler: nil)
            alartController.addAction(dismissAction)
            self.present(alartController, animated: true, completion: nil)
        })
    }
    
    @IBAction func confirmSampleDataRemoval(_ sender: AnyObject) {
        let alartController: UIAlertController = UIAlertController(title: "Confirm Deletion", message: "This will remove all sample data from your table. Do you want to continue?", preferredStyle: .alert)
        let proceedAction: UIAlertAction = UIAlertAction(title: "Yes", style: .default, handler: {(action: UIAlertAction) -> Void in
            self.removeSampleData()
        })
        let cancelAction: UIAlertAction = UIAlertAction(title: "No", style: .cancel, handler: nil)
        alartController.addAction(proceedAction)
        alartController.addAction(cancelAction)
        self.present(alartController, animated: true, completion: { _ in })
    }
    
    func removeSampleData() {
        activityIndicator.startAnimating()
        table?.removeSampleDataWithCompletionHandler?({(errors: [NSError]?) -> Void in
            self.activityIndicator.stopAnimating()
            var message: String = "All sample items were successfully removed from your table."
            if errors != nil {
                message = "Failed to remove sample items from your table."
            }
            let alartController: UIAlertController = UIAlertController(title: nil, message: message, preferredStyle: .alert)
            let dismissAction: UIAlertAction = UIAlertAction(title: "Dismiss", style: .cancel, handler: nil)
            alartController.addAction(dismissAction)
            self.present(alartController, animated: true, completion: nil)
        })
    }
    
    // MARK: - Utility Methods
    
    func showAlertWithTitle(_ title: String, message: String) {
        let alertController: UIAlertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let cancelAction: UIAlertAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(cancelAction)
        self.present(alertController, animated: true, completion: nil)
    }
}

class NoSQLTableCell: UITableViewCell {
    @IBOutlet weak var queryTypeLabel: UILabel!
    @IBOutlet weak var queryDescriptionLabel: UILabel!
    var queryType: String?
    
}
