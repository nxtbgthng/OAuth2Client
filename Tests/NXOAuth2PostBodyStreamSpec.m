#import "NXOAuth2PostBodyStream.h"


SpecBegin(NXOAuth2PostBodyStream)

describe(@"NXOAuth2PostBodyStream", ^{
    
    describe(@"-initWithParameters:", ^{
        it(@"returns an new instance", ^{
            NXOAuth2PostBodyStream *stream = [[NXOAuth2PostBodyStream alloc] initWithParameters:@{}];
            expect(stream).toNot.beNil();
        });
        
        it(@"does not crash on nil parameter", ^{
            NXOAuth2PostBodyStream *stream = [[NXOAuth2PostBodyStream alloc] initWithParameters:nil];
            expect(stream).toNot.beNil();
        });

        
        it(@"generates a boundary", ^{
            NXOAuth2PostBodyStream *stream = [[NXOAuth2PostBodyStream alloc] initWithParameters:@{}];
            expect(stream.boundary).toNot.beNil();
        });
    });
    
    
    describe(@".boundary", ^{
        it(@"is generated ", ^{
            NXOAuth2PostBodyStream *stream = [[NXOAuth2PostBodyStream alloc] initWithParameters:@{}];
            expect(stream).toNot.beNil();
        });
    });
    
    
    describe(@".length", ^{
        it(@"zero length with nil parameters", ^{
            NXOAuth2PostBodyStream *stream = [[NXOAuth2PostBodyStream alloc] initWithParameters:nil];
            expect(stream.length).to.equal(0);
        });
        
        xit(@"zero length with empty parameters", ^{
            NXOAuth2PostBodyStream *stream = [[NXOAuth2PostBodyStream alloc] initWithParameters:@{}];
            expect(stream.length).to.equal(0);
        });
        
        
        it(@"correct length for parameters", ^{
            NSDictionary *parameter = @{@"foo": @"bar",
                                        @"rab": @(0.0f)};
            NXOAuth2PostBodyStream *stream = [[NXOAuth2PostBodyStream alloc] initWithParameters:parameter];
            
            expect(stream.length).to.equal(204);
        });
    });
    
    
    describe(@"NSInputStream", ^{
        describe(@"-scheduleInRunLoop:forMode:", ^{
            it(@"triggers no assert when called", ^{
                NXOAuth2PostBodyStream *stream = [[NXOAuth2PostBodyStream alloc] initWithParameters:@{}];
                
                expect(^{
                    [stream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
                }).toNot.raiseAny();
            });
        });
        
        describe(@"-removeFromRunLoop:forMode:", ^{
            it(@"triggers no assert when called", ^{
                NXOAuth2PostBodyStream *stream = [[NXOAuth2PostBodyStream alloc] initWithParameters:@{}];
                
                expect(^{
                    [stream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
                }).toNot.raiseAny();
            });
        });
    });
});

SpecEnd
