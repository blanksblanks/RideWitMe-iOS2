//
//  GroupTableViewController.swift
//  citiBike
//
//  Created by 吴梦宇 on 12/17/15.
//  Copyright (c) 2015 ___mengyu wu___. All rights reserved.
//

import UIKit

class GroupTableViewController: UITableViewController {
    
    var groupTableRows:Array<DDBTableRow>?
    var lock:NSLock?
    
    var lastEvaluatedKey:[NSObject : AnyObject]!
    var  doneLoading = false
    
    var needsToRefresh = false
   
    override func viewDidLoad() {
        super.viewDidLoad()
        groupTableRows = []
        lock = NSLock()
        
        self.setupTable()
        
    }
    
    override func viewWillAppear(animated: Bool) {
       refreshList(false)
    }

    func setupTable() {
        //See if the test table exists.
        DDBDynamoDBManger.describeTable().continueWithExecutor(AWSExecutor.mainThreadExecutor(), withBlock: { (task:AWSTask!) -> AnyObject! in
            
            
            
            // If the test table doesn't exist, create one.
            if (task.error != nil && task.error.domain == AWSDynamoDBErrorDomain) && (task.error.code == AWSDynamoDBErrorType.ResourceNotFound.rawValue) {
                
                self.performSegueWithIdentifier("DDBLoadingViewSegue", sender: self)
                
                return DDBDynamoDBManger.createTable() .continueWithExecutor(AWSExecutor.mainThreadExecutor(), withBlock: { (task:AWSTask!) -> AnyObject! in
                    //Handle erros.
                    if ((task.error) != nil) {
                        print("Error: \(task.error)", terminator: "")
                        
                        
                        let alertController = UIAlertController(title: "Failed to setup a test table.", message: task.error.description, preferredStyle: UIAlertControllerStyle.Alert)
                        let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Cancel) { UIAlertAction -> Void in
                        }
                        alertController.addAction(okAction)
                        
                        self.presentViewController(alertController, animated: true, completion: nil)
                        
                        
                        
                    } else {
                        self.dismissViewControllerAnimated(false, completion: nil)
                    }
                    return nil
                    
                })
            } else {
                //load table contents
                print("table exist")
                self.refreshList(true)
            }
            
            return nil
        })
    }

    func refreshList(startFromBeginning: Bool)  {
        if (self.lock?.tryLock() != nil) {
            if startFromBeginning {
                self.lastEvaluatedKey = nil;
                self.doneLoading = false
            }
            
            
            UIApplication.sharedApplication().networkActivityIndicatorVisible = true
            
            let dynamoDBObjectMapper = AWSDynamoDBObjectMapper.defaultDynamoDBObjectMapper()
            let queryExpression = AWSDynamoDBScanExpression()
            queryExpression.exclusiveStartKey = self.lastEvaluatedKey
            queryExpression.limit = 20;
            dynamoDBObjectMapper.scan(DDBTableRow.self, expression: queryExpression).continueWithExecutor(AWSExecutor.mainThreadExecutor(), withBlock: { (task:AWSTask!) -> AnyObject! in
                
                if self.lastEvaluatedKey == nil {
                    self.groupTableRows?.removeAll(keepCapacity: true)
                }
                
                if task.result != nil {
                    let paginatedOutput = task.result as! AWSDynamoDBPaginatedOutput
                    for item in paginatedOutput.items as! [DDBTableRow] {
                        self.groupTableRows?.append(item)
                    }
                    
                    print("lastEvaluatedKey \(self.lastEvaluatedKey)")
                    self.lastEvaluatedKey = paginatedOutput.lastEvaluatedKey
                    if paginatedOutput.lastEvaluatedKey == nil {
                        self.doneLoading = true
                    }
                }
                
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                self.tableView.reloadData()
                
                if ((task.error) != nil) {
                    print("Error: \(task.error)", terminator: "")
                }
                return nil
            })
        }
    }

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Potentially incomplete method implementation.
        // Return the number of sections.
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete method implementation.
        // Return the number of rows in the section.
        if let rowCount = self.groupTableRows?.count {
            return rowCount;
        } else {
            return 0
        }
    }

   
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("GroupLabelCell", forIndexPath: indexPath) 

        // Configure the cell...
        if let myTableRows = self.groupTableRows {
            let item = myTableRows[indexPath.row]
            cell.textLabel?.text = "Group: \(item.GroupTitle!)"
            
            
            if indexPath.row == myTableRows.count - 1 && !self.doneLoading {
                self.refreshList(false)
            }
        }
        
        return cell as UITableViewCell
        
    }
    


    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the specified item to be editable.
        return true
    }
    

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */
    
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            if var myTableRows = self.groupTableRows {
                let item = myTableRows[indexPath.row]
                self.deleteTableRow(item)
                myTableRows.removeAtIndex(indexPath.row)
                self.groupTableRows = myTableRows
                
                tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
            }
            
            
        }
    }
    
    func deleteTableRow(row: DDBTableRow) {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        
        let dynamoDBObjectMapper = AWSDynamoDBObjectMapper.defaultDynamoDBObjectMapper()
        dynamoDBObjectMapper.remove(row).continueWithExecutor(AWSExecutor.mainThreadExecutor(), withBlock: { (task:AWSTask!) -> AnyObject! in
            
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            
            if ((task.error) != nil) {
                print("Error: \(task.error)", terminator: "")
                
                let alertController = UIAlertController(title: "Failed to delete a row.", message: task.error.description, preferredStyle: UIAlertControllerStyle.Alert)
                let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Cancel){UIAlertAction -> Void in
                }
                alertController.addAction(okAction)
                self.presentViewController(alertController, animated: true, completion: nil)
                
                
            }
            return nil
        })
        
    }

    
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        //also need to check password
        self.performSegueWithIdentifier("DDBSeguePushGroupLocationViewController", sender: tableView.cellForRowAtIndexPath(indexPath))
    }

    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
        if segue.identifier == "DDBSeguePushGroupLocationViewController" {
            let detailViewController = segue.destinationViewController as! GroupLocationViewController
            if sender != nil {
                
                    let cell = sender as! UITableViewCell
                
                    let indexPath = self.tableView.indexPathForCell(cell)
                    let tableRow = self.groupTableRows?[indexPath!.row]
                    detailViewController.groupLocationInfo = tableRow

            }
        }
        
        
        
    }

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

}
