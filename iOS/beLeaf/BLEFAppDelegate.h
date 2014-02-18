//
//  BLEFAppDelegate.h
//  beLeaf
//
//  Created by Ashley Cutmore on 19/12/2013.
//  Copyright (c) 2013 DocMcs13group12. All rights reserved.
//

#import <UIKit/UIKit.h>

@class BLEFServerInterface;

@interface BLEFAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (readonly, strong, nonatomic) BLEFServerInterface *serverinterface;

- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;

@end
