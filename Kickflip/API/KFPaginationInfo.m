//
//  KFPaginationInfo.m
//  Pods
//
//  Created by Christopher Ballinger on 5/2/14.
//
//

#import "KFPaginationInfo.h"

@implementation KFPaginationInfo

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{
             NSStringFromSelector(@selector(nextPageAvailable)): @"next_page_available",
             NSStringFromSelector(@selector(currentPage)): @"page_number",
             NSStringFromSelector(@selector(itemsPerPage)): @"results_per_page",
             NSStringFromSelector(@selector(totalItems)): @"total_items",
             };
}

@end
