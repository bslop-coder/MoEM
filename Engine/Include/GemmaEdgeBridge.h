#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface GemmaEdgeDiagnostics : NSObject

@property (nonatomic, copy, readonly) NSString *metalDeviceName;
@property (nonatomic, readonly) BOOL metalSupported;
@property (nonatomic, readonly) BOOL hasUnifiedMemory;
@property (nonatomic, readonly) BOOL llamaGpuOffloadSupported;
@property (nonatomic, readonly) BOOL llamaMmapSupported;
@property (nonatomic, readonly) NSUInteger llamaMaxDevices;
@property (nonatomic, readonly) double recommendedWorkingSetMB;
@property (nonatomic, readonly) double physicalMemoryMB;
@property (nonatomic, readonly) double physFootprintMB;
@property (nonatomic, readonly) double procAvailableMemoryMB;
@property (nonatomic, readonly) double estimatedJetsamCeilingMB;
@property (nonatomic, readonly) double suggestedHotExpertBudgetMB;
@property (nonatomic, copy, readonly) NSString *llamaSystemInfo;

@end

@interface GemmaEdgeBridge : NSObject

+ (GemmaEdgeDiagnostics *)probeSystem;

@end

NS_ASSUME_NONNULL_END
