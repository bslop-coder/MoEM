#import "GemmaEdgeBridge.h"

#import <Metal/Metal.h>
#import <mach/mach.h>
#import <os/proc.h>
#import <dispatch/dispatch.h>

#import <llama/llama.h>

@interface GemmaEdgeDiagnostics ()
@property (nonatomic, copy, readwrite) NSString *metalDeviceName;
@property (nonatomic, readwrite) BOOL metalSupported;
@property (nonatomic, readwrite) BOOL hasUnifiedMemory;
@property (nonatomic, readwrite) BOOL llamaGpuOffloadSupported;
@property (nonatomic, readwrite) BOOL llamaMmapSupported;
@property (nonatomic, readwrite) NSUInteger llamaMaxDevices;
@property (nonatomic, readwrite) double recommendedWorkingSetMB;
@property (nonatomic, readwrite) double physicalMemoryMB;
@property (nonatomic, readwrite) double physFootprintMB;
@property (nonatomic, readwrite) double procAvailableMemoryMB;
@property (nonatomic, readwrite) double estimatedJetsamCeilingMB;
@property (nonatomic, readwrite) double suggestedHotExpertBudgetMB;
@property (nonatomic, copy, readwrite) NSString *llamaSystemInfo;
@end

@implementation GemmaEdgeDiagnostics
@end

static double bytesToMiB(uint64_t bytes) {
    return static_cast<double>(bytes) / (1024.0 * 1024.0);
}

static uint64_t queryPhysFootprintBytes(void) {
    task_vm_info_data_t vmInfo;
    mach_msg_type_number_t count = TASK_VM_INFO_COUNT;
    kern_return_t kr = task_info(mach_task_self(), TASK_VM_INFO, (task_info_t)&vmInfo, &count);
    if (kr == KERN_SUCCESS) {
        return static_cast<uint64_t>(vmInfo.phys_footprint);
    }
    return 0;
}

@implementation GemmaEdgeBridge

+ (void)ensureBackendInitialized {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        llama_backend_init();
    });
}

+ (GemmaEdgeDiagnostics *)probeSystem {
    [self ensureBackendInitialized];

    GemmaEdgeDiagnostics *diag = [[GemmaEdgeDiagnostics alloc] init];

    id<MTLDevice> mtlDevice = MTLCreateSystemDefaultDevice();
    if (mtlDevice != nil) {
        diag.metalSupported = YES;
        diag.metalDeviceName = mtlDevice.name ?: @"Apple Metal GPU";
        diag.hasUnifiedMemory = mtlDevice.hasUnifiedMemory;
        diag.recommendedWorkingSetMB = bytesToMiB(mtlDevice.recommendedMaxWorkingSetSize);
    } else {
        diag.metalSupported = NO;
        diag.metalDeviceName = @"Unavailable";
        diag.hasUnifiedMemory = NO;
        diag.recommendedWorkingSetMB = 0.0;
    }

    diag.llamaGpuOffloadSupported = llama_supports_gpu_offload() ? YES : NO;
    diag.llamaMmapSupported = llama_supports_mmap() ? YES : NO;
    diag.llamaMaxDevices = static_cast<NSUInteger>(llama_max_devices());

    const char *sysInfoCStr = llama_print_system_info();
    diag.llamaSystemInfo = sysInfoCStr ? [NSString stringWithUTF8String:sysInfoCStr] : @"";

    uint64_t totalRAM = [NSProcessInfo processInfo].physicalMemory;
    uint64_t footprint = queryPhysFootprintBytes();
    uint64_t available = static_cast<uint64_t>(os_proc_available_memory());
    uint64_t jetsamEst = footprint + available;

    diag.physicalMemoryMB = bytesToMiB(totalRAM);
    diag.physFootprintMB = bytesToMiB(footprint);
    diag.procAvailableMemoryMB = bytesToMiB(available);
    diag.estimatedJetsamCeilingMB = bytesToMiB(jetsamEst);

    // Reserve ~1.55 GiB for non-expert resident weights + ~0.40 GiB KV/Metal/UI + ~0.45 GiB Jetsam safety margin
    double reservedMB = 2400.0;
    double expertBudget = diag.estimatedJetsamCeilingMB - reservedMB;
    diag.suggestedHotExpertBudgetMB = expertBudget > 256.0 ? expertBudget : 256.0;

    return diag;
}

@end
