/*
 Copyright (c) 2013, OpenEmu Team

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

#import "OEGameShader.h"
#import <Cg/Cg.h>
#import <Cg/cgGL.h>

typedef enum
{
    OEScaleTypeSource,
    OEScaleTypeViewPort,
    OEScaleTypeAbsolute
} OEScaleType;

@interface OECGShader : OEGameShader

- (void)compileShaders;

@property(readonly) CGprofile vertexProfile;
@property(readonly) CGprofile fragmentProfile;
@property(readonly) CGprogram vertexProgram;
@property(readonly) CGprogram fragmentProgram;

@property(readonly) CGparameter position;
@property(readonly) CGparameter texCoord;
@property(readonly) CGparameter modelViewProj;
@property(readonly) CGparameter vertexVideoSize;
@property(readonly) CGparameter vertexTextureSize;
@property(readonly) CGparameter vertexOutputSize;
@property(readonly) CGparameter vertexFrameCount;
@property(readonly) CGparameter vertexFrameDirection;
@property(readonly) CGparameter vertexFrameRotation;
@property(readonly) CGparameter fragmentVideoSize;
@property(readonly) CGparameter fragmentTextureSize;
@property(readonly) CGparameter fragmentOutputSize;
@property(readonly) CGparameter fragmentFrameCount;
@property(readonly) CGparameter fragmentFrameDirection;
@property(readonly) CGparameter fragmentFrameRotation;

@property BOOL linearFiltering;
@property OEScaleType scaleType;
@property CGSize scaler;

- (CGparameter)vertexParameterWithName:(const char *)theParameterName;
- (CGparameter)fragmentParameterWithName:(const char *)theParameterName;


@end
