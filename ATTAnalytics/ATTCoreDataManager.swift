//
//  ATTCoreDataManager.swift
//  TrackingHelper
//
//  Created by Sreekanth R on 23/01/17.
//  Copyright © 2017 Sreekanth R. All rights reserved.
//

import UIKit
import CoreData

class ATTCoreDataManager: NSObject {
    // MARK: - Core Data stack
    @available(iOS 10.0, *)
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "ATTDB")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    // MARK: Screen view methods
    func createScreenView(screenViewModel:ATTScreenViewModel?) -> Void {
        if screenViewModel != nil {
            if #available(iOS 10.0, *) {
                let managedContext = self.persistentContainer.viewContext
                let entity = NSEntityDescription.entity(forEntityName: "Screen",
                                                        in: managedContext)!
                
                let aScreen = NSManagedObject(entity: entity, insertInto: managedContext)
                
                aScreen.setValue(screenViewModel?.screenViewID,         forKeyPath: "screenViewID")
                aScreen.setValue(screenViewModel?.previousScreenName,   forKeyPath: "previousScreen")
                aScreen.setValue(screenViewModel?.screenName,           forKeyPath: "presentScreen")
                aScreen.setValue(screenViewModel?.screeViewDuration,    forKeyPath: "screenWatchDuration")
                aScreen.setValue(screenViewModel?.screenViewBeginTime,  forKeyPath: "screenWatchedTime")
                aScreen.setValue(screenViewModel?.latitude,             forKeyPath: "latitude")
                aScreen.setValue(screenViewModel?.longitude,            forKeyPath: "longitude")
                aScreen.setValue(false,                                 forKeyPath: "syncStatus")
                
                self.saveContext()
                
            } else {
                // Fallback on earlier versions
            }
        }
    }
    
    func updateScreenView(screenViewModel:ATTScreenViewModel?) -> Void {
        if #available(iOS 10.0, *) {
            let managedContext = self.persistentContainer.viewContext
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Screen")
            
            fetchRequest.predicate = NSPredicate(format: "screenViewID = %@", (screenViewModel?.screenViewID)!)
            
            do {
                let results = try managedContext.fetch(fetchRequest) as Array<AnyObject>
                if (results.count) > 0 {
                    let managedObject = results[0]
                    managedObject.setValue(screenViewModel?.previousScreenName, forKey: "previousScreen")
                    managedObject.setValue(screenViewModel?.screeViewDuration, forKey: "screenWatchDuration")
                    
                    self.saveContext()
                }
            } catch let error as NSError {
                print("Could not save. \(error), \(error.userInfo)")
            }
            
        } else {
            // Fallback on earlier versions
        }
    }
    
    func fetchAllScreens() -> Array<AnyObject>? {
        if #available(iOS 10.0, *) {
            let managedContext = self.persistentContainer.viewContext
            let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Screen")
            do {
                let data:Array<AnyObject> = try managedContext.fetch(fetchRequest)
                return data
            } catch let error as NSError {
                print("Could not fetch. \(error), \(error.userInfo)")
            }
        } else {
            // Fallback on earlier versions
            return nil
        }
        
        return nil
    }
    
    func createEvents(event:ATTEventModel?) -> Void {
        if event != nil {
            if #available(iOS 10.0, *) {
                let managedContext = self.persistentContainer.viewContext
                let entity = NSEntityDescription.entity(forEntityName: "Events",
                                                        in: managedContext)!
                
                let anEvent = NSManagedObject(entity: entity, insertInto: managedContext)
                
                anEvent.setValue(event?.screenViewID,   forKeyPath: "screenViewID")
                anEvent.setValue(event?.eventType,      forKeyPath: "eventType")
                anEvent.setValue(event?.eventStartTime, forKeyPath: "eventStartTime")
                anEvent.setValue(event?.eventName,      forKeyPath: "eventName")
                anEvent.setValue(event?.eventDuration,  forKeyPath: "eventDuration")
                anEvent.setValue(event?.latitude,       forKeyPath: "latitude")
                anEvent.setValue(event?.longitude,      forKeyPath: "longitude")
                
                if event?.dataURL != nil {
                    anEvent.setValue(event?.dataURL, forKeyPath: "dataURL")
                }
                
                if event?.arguments != nil {
                    let data = try? JSONSerialization.data(withJSONObject: (event?.arguments)!, options: [])
                    anEvent.setValue(data, forKeyPath: "customParam")
                }
                
                self.saveContext()
                
            } else {
                // Fallback on earlier versions
            }
        }
    }
    
    func fetchEventWithScreenID(screenID:String?) -> Array<AnyObject>? {
        if #available(iOS 10.0, *) {
            let managedContext = self.persistentContainer.viewContext
            let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Events")
            fetchRequest.predicate = NSPredicate(format: "screenViewID = %@", screenID!)
            do {
                let data:Array<AnyObject> = try managedContext.fetch(fetchRequest)
                return data
            } catch let error as NSError {
                print("Could not fetch. \(error), \(error.userInfo)")
            }
        } else {
            // Fallback on earlier versions
            return nil
        }
        
        return nil
    }
    
    // MARK: Call back sync
    func removeSyncedObjects(screenIDArray:Array<String?>) -> Void {
        for eachScreenID in screenIDArray {
            self.deleteSyncableObjects(screenID: eachScreenID, forEntity: "Screen")
            self.deleteSyncableObjects(screenID: eachScreenID, forEntity: "Events")
            
            self.saveContext()
        }
    }
    
    func deleteSyncableObjects(screenID:String?, forEntity entityName:String?) -> Void {
        if #available(iOS 10.0, *) {
            let managedContext = self.persistentContainer.viewContext
            let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: entityName!)
            fetchRequest.predicate = NSPredicate(format: "screenViewID = %@", screenID!)
            do {
                let results = try managedContext.fetch(fetchRequest) as Array<AnyObject>
                if (results.count) > 0 {
                    for eachScreen in results {
                        managedContext.delete(eachScreen as! NSManagedObject)
                    }
                }
            } catch let error as NSError {
                print("Could not save. \(error), \(error.userInfo)")
            }
        } else {
            // Fallback on earlier versions
        }
    }
    
    // MARK: - Core Data Saving support    
    func saveContext () {
        if #available(iOS 10.0, *) {
            let context = self.persistentContainer.viewContext
            if context.hasChanges {
                do {
                    try context.save()
                } catch {                    
                    let nserror = error as NSError
                    fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
                }
            }
        } else {
            // Fallback on earlier versions
        }
    }
}
