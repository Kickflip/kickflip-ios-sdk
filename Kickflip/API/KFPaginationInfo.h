//
//  KFPaginationInfo.h
//  Pods
//
//  Created by Christopher Ballinger on 5/2/14.
//
//

#import <Foundation/Foundation.h>
#import "Mantle.h"

/**
 *  Additional pagination metadata for responses that return a list of objects.
 */
@interface KFPaginationInfo : MTLModel <MTLJSONSerializing>

/**
 *  Whether or not another page of results is available.
 */
@property (nonatomic, readonly) BOOL nextPageAvailable;

/**
 *  Total number of remote items that match query.
 */
@property (nonatomic, readonly) NSUInteger totalItems;

/**
 *  Mirrors the requested itemsPerPage.
 */
@property (nonatomic, readonly) NSUInteger itemsPerPage;

/**
 *  Mirrors the currently requested page.
 *  @note The first page starts at 1 instead of 0.
 */
@property (nonatomic, readonly) NSUInteger currentPage;

@end
