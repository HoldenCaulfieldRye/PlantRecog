//
//  BLEFCaptureBuffer.m
//  beLeaf
//
//  Created by Ashley Cutmore on 11/03/2014.
//  Copyright (c) 2014 DocMcs13group12. All rights reserved.
//

#import "BLEFCaptureBuffer.h"

@interface BLEFCaptureBuffer ()

@property (strong, nonatomic) NSMutableDictionary *slots;
@property (strong, nonatomic) BLEFSpecimen *specimen;
@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) CLLocation *location;
@property (strong, nonatomic) BLEFCaptureBuffer* safetyCycle;
@property (strong, nonatomic) NSMutableSet *completedSlots;

@end

@implementation BLEFCaptureBuffer

- (id)initWithSlots:(NSArray *)slotNames usingDatabase:(BLEFDatabase *)database
{
    self = [super init];
    if (self){
        
        _slots = [[NSMutableDictionary alloc] initWithCapacity:[slotNames count]];
        
        for (NSString* slotName in slotNames){
            [_slots setValue:[NSNull null] forKey:slotName];
        }

        _database = database;
        
        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        _locationManager.delegate = self;
        _location = nil;
        [[self locationManager] startUpdatingLocation];

        _completedSlots = [[NSMutableSet alloc] initWithCapacity:[slotNames count]];
    }
    return self;
}

- (void)finalize
{
    [_locationManager stopUpdatingLocation];
}

-(BLEFSpecimen *)specimen
{
    if (_specimen){
        return _specimen;
    } else {
        _specimen = [[self database] newSpecimen];
        return [self specimen];
    }
}

-(BOOL)addData:(NSData *)data toSlot:(NSString *)slotName
{
    if ([[self completedSlots] containsObject:slotName]){
        return false;
    }
    
    if (data && slotName && [self slots]){
        if ([[[self slots] valueForKey:slotName] isKindOfClass:[NSNull class]]){
            [[self slots] setValue:data forKey:slotName];
            [[self slots] count];
            return true;
        }
    }
    return false;
}

- (BOOL)removeDataForSlot:(NSString *)slotName
{
    if (slotName && [self slots]){
        if ([[[self slots] valueForKey:slotName] isKindOfClass:[NSData class]]){
            [[self slots] setObject:[NSNull null] forKey:slotName];
            return true;
        }
    }
    return false;
}

- (UIImage *)imageForSlotNamed:(NSString *)slotName
{
    if (slotName && [self slots]){
        id slotContents = [[self slots] valueForKey:slotName];
        if (slotContents != nil && [slotContents isKindOfClass:[NSData class]]){
            return [UIImage imageWithData:slotContents];
        }
    }
    return NULL;
}

- (BOOL)completeSlotNamed:(NSString *)slotName completion:(void (^)(BOOL))handler
{
    if (slotName && [self slots]){
        if (![[self completedSlots] containsObject:slotName]){
            NSData *dataToSave = [[self slots] valueForKey:slotName];
            if (dataToSave && [dataToSave isKindOfClass:[NSData class]]){
                [[self completedSlots] addObject:slotName];
                BLEFObservation *observation = [_database addNewObservationToSpecimen:[self specimen]];
                [observation setSegment:slotName];
            
                NSNumber *longitude = [NSNumber numberWithDouble:0.0];
                NSNumber *latitude = [NSNumber numberWithDouble:0.0];
                if ([self location] != nil){
                    longitude = [NSNumber numberWithDouble:_location.coordinate.longitude];
                    latitude = [NSNumber numberWithDouble:_location.coordinate.latitude];
                }
            
                [[observation specimen] setLatitude:[latitude doubleValue]];
                [[observation specimen] setLongitude:[longitude doubleValue]];
            
                [observation generateThumbnailFromImage:[UIImage imageWithData:dataToSave]];
                [self setSafetyCycle:self];
                [observation saveImage:dataToSave completion:^(BOOL success) {
                    if (handler) handler(success);
                    _safetyCycle = nil;
                }];
                return true;
            }
        }
    }
    if (handler){handler(false);}
    return false;
}

- (NSInteger)count
{
    return [[self slots] count];
}

- (BOOL)slotComplete:(NSString *)slotName
{
    return [[self completedSlots] containsObject:slotName];
}

- (void)completeCapture
{
    BLEFSpecimen *specimen = [self specimen];
    [specimen setComplete:true];
    if ([[specimen observations] count] == 0){
        [[_database managedObjectContext] deleteObject:specimen];
    }
}

- (void)deleteSession
{
    BLEFSpecimen *specimen = [self specimen];
    [[_database managedObjectContext] deleteObject:specimen];
}

#pragma mark - Location Delegate Methods

-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    [self setLocation:[locations lastObject]];
}

@end
