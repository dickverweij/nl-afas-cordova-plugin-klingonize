/*
The MIT License (MIT)

Copyright (c) 2015 Dick Verweij dickydick1969@hotmail.com, d.verweij@afas.nl

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/
#import "CameraBooth.h"
#import <Cordova/CDV.h>
#import <CoreImage/CoreImage.h>
#import <QuartzCore/QuartzCore.h>


static inline double radians (double degrees) {return degrees * M_PI/180;}

@implementation Klingonize


-(UIImage *)resizeImage:(UIImage *)image {
    
    CGImageRef imageRef = [image CGImage];
    CGImageAlphaInfo alphaInfo = CGImageGetAlphaInfo(imageRef);
    CGColorSpaceRef colorSpaceInfo = CGColorSpaceCreateDeviceRGB();
    
    if (alphaInfo == kCGImageAlphaNone)
        alphaInfo = kCGImageAlphaNoneSkipLast;
    
    int width, height;
    
    width = [image size].width;
    height = [image size].height;
    
    CGContextRef bitmap;
    
    if (image.imageOrientation == UIImageOrientationUp | image.imageOrientation == UIImageOrientationDown) {
        bitmap = CGBitmapContextCreate(NULL, width, height, CGImageGetBitsPerComponent(imageRef), CGImageGetBytesPerRow(imageRef), colorSpaceInfo, alphaInfo);
        
    } else {
        bitmap = CGBitmapContextCreate(NULL, height, width, CGImageGetBitsPerComponent(imageRef), CGImageGetBytesPerRow(imageRef), colorSpaceInfo, alphaInfo);
        
    }
    
    if (image.imageOrientation == UIImageOrientationLeft) {
        NSLog(@"image orientation left");
        CGContextRotateCTM (bitmap, radians(90));
        CGContextTranslateCTM (bitmap, 0, -height);
        
    } else if (image.imageOrientation == UIImageOrientationRight) {
        NSLog(@"image orientation right");
        CGContextRotateCTM (bitmap, radians(-90));
        CGContextTranslateCTM (bitmap, -width, 0);
        
    } else if (image.imageOrientation == UIImageOrientationUp) {
        NSLog(@"image orientation up");
        
    } else if (image.imageOrientation == UIImageOrientationDown) {
        NSLog(@"image orientation down");
        CGContextTranslateCTM (bitmap, width,height);
        CGContextRotateCTM (bitmap, radians(-180.));
        
    }
    
    CGContextDrawImage(bitmap, CGRectMake(0, 0, width, height), imageRef);
    CGImageRef ref = CGBitmapContextCreateImage(bitmap);
    UIImage *result = [UIImage imageWithCGImage:ref];
    
    CGContextRelease(bitmap);
    CGImageRelease(ref);
    
    return result;
}

-(NSArray *)markFaces:(UIImageView *)imageView withTransform:(CGAffineTransform) transform
{
    NSMutableArray * resultArray = [[NSMutableArray alloc]init];
    
    CIImage *image = [CIImage imageWithCGImage:imageView.image.CGImage];
    
    
    CIDetector *detector = [CIDetector detectorOfType:CIDetectorTypeFace context:nil options:[NSDictionary dictionaryWithObject:CIDetectorAccuracyHigh forKey:CIDetectorAccuracy]];
    
    NSArray *features = [detector featuresInImage:image];
    
    if ([features count]==0) {
        resultArray = nil;
    }
    
    for (CIFaceFeature *faceFeature in features) {
        NSMutableDictionary * faceDict = [[NSMutableDictionary alloc]init];
    
        CGRect faceRect = CGRectApplyAffineTransform(faceFeature.bounds, transform);
        
        [faceDict setValue:NSStringFromCGRect(faceRect) forKey:@"face"];
        
        if (faceFeature.hasRightEyePosition) {
            
            CGPoint rightEyePos = CGPointApplyAffineTransform(faceFeature.rightEyePosition, transform);
            [faceDict setValue:NSStringFromCGPoint(rightEyePos) forKey:@"right_eye"];
            
        }
        
        if (faceFeature.hasLeftEyePosition) {
            
            CGPoint leftEyePos = CGPointApplyAffineTransform(faceFeature.leftEyePosition, transform);
            [faceDict setValue:NSStringFromCGPoint(leftEyePos) forKey:@"left_eye"];
            
        }
        
        if (faceFeature.hasMouthPosition) {
            
            CGPoint mouthPos = CGPointApplyAffineTransform(faceFeature.mouthPosition, transform);
            [faceDict setValue:NSStringFromCGPoint(mouthPos) forKey:@"mouth"];
            
        }
        
        [resultArray addObject:faceDict];
    }
    
    return resultArray;
    
}

- (BOOL)isGrayScale: (UIImage *) image {
    CGImageRef imageRef = image.CGImage;
    
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(imageRef);
    if (CGColorSpaceGetModel(colorSpace) == kCGColorSpaceModelRGB) {
        CGDataProviderRef dataProvider = CGImageGetDataProvider(imageRef);
        CFDataRef imageData = CGDataProviderCopyData(dataProvider);
        const UInt8 *rawData = CFDataGetBytePtr(imageData);
        
        size_t width = CGImageGetWidth(imageRef);
        size_t height = CGImageGetHeight(imageRef);
        
        int byteIndex = 0;
        BOOL allPixelsGrayScale = YES;
        for(int ii = 0 ; ii <width*height; ++ii)
        {
            int r = rawData[byteIndex];
            int g = rawData[byteIndex+1];
            int b = rawData[byteIndex+2];
            if (!((r == g)&&(g == b))) {
                allPixelsGrayScale = NO;
                break;
            }
            byteIndex += 4;
        }
        CFRelease(imageData);
        CGColorSpaceRelease(colorSpace);
        return allPixelsGrayScale;
    }
    else if (CGColorSpaceGetModel(colorSpace) == kCGColorSpaceModelMonochrome){
        CGColorSpaceRelease(colorSpace); return YES;}
    else {CGColorSpaceRelease(colorSpace); return NO;}
}

- (UIImage * ) klingonizeImage: (UIImage *) image {
    
    UIImageView *imageCopy = [[UIImageView alloc] initWithImage:[self resizeImage:image]];
    
    
    CGAffineTransform transform = CGAffineTransformMakeScale(1, -1);
    transform = CGAffineTransformTranslate(transform,
                                           0,-imageCopy.bounds.size.height);
    NSArray * result = [self markFaces:imageCopy withTransform:transform];
    
    if (result != nil && result.count ==1) {
        NSMutableDictionary * faceDict = [result objectAtIndex:0];
        
        UIImage * klingonface;
        if ([self isGrayScale:image]) {
            klingonface = [UIImage imageNamed:@"klingonfaceBW.png"];
        }
        else {
            klingonface = [UIImage imageNamed:@"klingonface.png"];
        }
        
        // begin a graphics context of sufficient size
        UIGraphicsBeginImageContext(image.size);
        
        // draw original image into the context
        [image drawAtPoint:CGPointZero];
        
        
        CGRect faceRect = CGRectFromString([faceDict  objectForKey:@"face"] );
        CGPoint pLeftEye = CGPointFromString([faceDict objectForKey:@"left_eye"]);
        
        
        faceRect = CGRectInset(faceRect, (pLeftEye.x - faceRect.origin.x) *0.5, (pLeftEye.y - faceRect.origin.y) * 0.8);
        faceRect.size.height *= 1.4;
        
        
        CGFloat sx = faceRect.size.width / 163.0;
        CGFloat sy = faceRect.size.height / 183.0;
        CGFloat ssx = sx * 552.0;
        CGFloat ssy = sy * 634.0;
        
        CGFloat ox = faceRect.origin.x - ssx;
        CGFloat oy = faceRect.origin.y - ssy;
        
        CGRect scaledRect = CGRectMake(ox, oy, klingonface.size.width* sx, klingonface.size.height * sy);
        
        [klingonface drawInRect:scaledRect];
        
        // make image out of bitmap context
        UIImage *retImage = UIGraphicsGetImageFromCurrentImageContext();
        
        // free the context
        UIGraphicsEndImageContext();
        
        return retImage;
    }
    
    return image;
}



- (void)klingonize:(CDVInvokedUrlCommand *)command {
    NSString * result = nil;
    
    if (command.arguments.count == 2 && ((NSString *)command.arguments[1]).length > 0) {
    
        @try {
            NSData * imageData = [[NSData alloc ] initWithBase64EncodedString:command.arguments[1] options:0];
    
            UIImage * retImage = [self klingonizeImage:[UIImage imageWithData:imageData]];
        
            if ([((NSString *)command.arguments[0]) containsString:@"png"]) {
                result = [UIImagePNGRepresentation(retImage) base64EncodedStringWithOptions:0];
            }
            else {
                result = [UIImageJPEGRepresentation(retImage, 1.0)  base64EncodedStringWithOptions:0];
            }
        }
        @catch (NSException * ex)
        {
            result = command.arguments[1];
        }
    }
    
	CDVPluginResult * pluginResult;
    if (result != nil) {
		pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString: result ];
	} 
	else  {
		pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR ];
	}
    
    [self.commandDelegate sendPluginResult:pluginResult callbackId: command.callbackId];
    
}


@end
