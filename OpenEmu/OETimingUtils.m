/*
 Copyright (c) 2012 Alexander Strange
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
 * Redistributions of source code must retain the above copyright
 notice, this list of conditions and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright
 notice, this list of conditions and the following disclaimer in the
 documentation and/or other materials provided with the distribution.
 * Neither the name of the OpenEmu Team nor the
 names of its contributors may be used to endorse or promote products
 derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY OpenEmu Team ''AS IS'' AND ANY
 EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL OpenEmu Team BE LIABLE FOR ANY
 DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "OETimingUtils.h"
#import <mach/mach_time.h>

static double mach_to_sec = 0;

static void init_mach_time()
{
    if (!mach_to_sec) {
        struct mach_timebase_info base;
        mach_timebase_info(&base);
        mach_to_sec = base.numer / (double)base.denom;
        
        mach_to_sec = 1e-9 * mach_to_sec;
    }
}

NSTimeInterval OEMonotonicTime()
{    
    init_mach_time();
    
    return mach_absolute_time() * mach_to_sec;
}

@interface OEPerfMonitorObservation : NSObject
@property (nonatomic) NSTimeInterval totalTime;
@property (nonatomic) NSInteger numTimesRun;
@property (nonatomic) NSInteger numTimesOver;
@end

@implementation OEPerfMonitorObservation
{
@public
    NSString *name;
    NSTimeInterval maximumTime;
    
    NSTimeInterval lastTime;
    
    NSTimeInterval *sampledDiffs;
    int n;
}
@synthesize totalTime, numTimesRun, numTimesOver;
@end

static NSMutableDictionary *observations;
static const int samplePeriod = 480;

static void OEPerfMonitorRecordEvent(OEPerfMonitorObservation *observation, NSTimeInterval diff)
{
    observation.totalTime += diff;
    observation.numTimesRun++;
    if (diff >= observation->maximumTime)
        observation.numTimesOver++;
    
    NSTimeInterval avg = observation.totalTime / observation.numTimesRun;
    
    if (observation->n == samplePeriod) {
        NSTimeInterval variance=0;
        int i = 0;
        
        for (i = 0; i < samplePeriod; i++) {
            NSTimeInterval s = observation->sampledDiffs[i] - avg;
            variance += s*s;
        }
        
        NSTimeInterval stddev = sqrt(variance / observation.numTimesRun);
        
        NSLog(@"%@: avg %fs (%f fps), std.dev %fs (%f fps) / over %ld/%ld = %f%%", observation->name,
              avg, 1/avg, stddev, 1/stddev, observation.numTimesOver, observation.numTimesRun,
              100. * (observation.numTimesOver/(float)observation.numTimesRun));
        observation->n = 0;
    }
    
    observation->sampledDiffs[observation->n++] = diff;
}

static OEPerfMonitorObservation *OEPerfMonitorGetObservation(NSString *name, NSTimeInterval maximumTime)
{
    if (!observations) observations = [NSMutableDictionary new];
    
    OEPerfMonitorObservation *observation = [observations objectForKey:name];
    
    if (!observation) {
        observation = [[OEPerfMonitorObservation alloc] init];
        observation->sampledDiffs = calloc(samplePeriod, sizeof(NSTimeInterval));
        observation->name = name;
        observation->maximumTime = maximumTime;
        [observations setObject:observation forKey:name];
    }
    
    return observation;
}

void OEPerfMonitorSignpost(NSString *name, NSTimeInterval maximumTime)
{
    OEPerfMonitorObservation *observation = OEPerfMonitorGetObservation(name, maximumTime);
    
    NSTimeInterval time2 = OEMonotonicTime();
    
    if (!observation->lastTime) {
        observation->lastTime = time2;
        return;
    }

    OEPerfMonitorRecordEvent(observation, time2 - observation->lastTime);
    observation->lastTime = time2;
}

void OEPerfMonitorObserve(NSString *name, NSTimeInterval maximumTime, void (^block)())
{
    OEPerfMonitorObservation *observation = OEPerfMonitorGetObservation(name, maximumTime);
    
    NSTimeInterval time1 = OEMonotonicTime();
    block();
    NSTimeInterval time2 = OEMonotonicTime();
    
    OEPerfMonitorRecordEvent(observation, time2 - time1);
}

#include <mach/mach_init.h>
#include <mach/thread_policy.h>
#include <mach/thread_act.h>
#include <pthread.h>

int OESetThreadRealtime(NSTimeInterval period, NSTimeInterval computation, NSTimeInterval constraint) {
    struct thread_time_constraint_policy ttcpolicy;
    int ret;
    thread_port_t threadport = pthread_mach_thread_np(pthread_self());
    
    init_mach_time();

    assert(computation < .05);
    assert(computation < constraint);
    
    NSLog(@"RT policy: %fs (limit %fs) every %fs", computation, constraint, period);
    
    ttcpolicy.period=period / mach_to_sec; 
    ttcpolicy.computation=computation / mach_to_sec;
    ttcpolicy.constraint=constraint / mach_to_sec;
    ttcpolicy.preemptible=1;
    
    if ((ret=thread_policy_set(threadport,
                               THREAD_TIME_CONSTRAINT_POLICY, (thread_policy_t)&ttcpolicy,
                               THREAD_TIME_CONSTRAINT_POLICY_COUNT)) != KERN_SUCCESS) {
        NSLog(@"OESetThreadRealtime() failed.");
        return 0;
    }
    return 1;
}