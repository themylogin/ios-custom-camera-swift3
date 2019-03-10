//
//  OpenCVWrapper.m
//  CustomCamera
//
//  Created by themylogin on 10/03/2019.
//  Copyright © 2019 FAYA Corporation. All rights reserved.
//

#import "OpenCVWrapper.h"

#import <opencv2/opencv.hpp>

using namespace cv;

@implementation OpenCVWrapper

+ (cv::Mat)cvMatFromUIImage:(UIImage *)image
{
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    CGFloat cols = image.size.width;
    CGFloat rows = image.size.height;
    
    cv::Mat cvMat(rows, cols, CV_8UC4); // 8 bits per component, 4 channels (color channels + alpha)
    
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to  data
                                                    cols,                       // Width of bitmap
                                                    rows,                       // Height of bitmap
                                                    8,                          // Bits per component
                                                    cvMat.step[0],              // Bytes per row
                                                    colorSpace,                 // Colorspace
                                                    kCGImageAlphaNoneSkipLast |
                                                    kCGBitmapByteOrderDefault); // Bitmap info flags
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
    CGContextRelease(contextRef);
    
    return cvMat;
}

+ (UIImage *)UIImageFromCVMat:(cv::Mat)cvMat
{
    NSData *data = [NSData dataWithBytes:cvMat.data length:cvMat.elemSize()*cvMat.total()];
    CGColorSpaceRef colorSpace;
    
    if (cvMat.elemSize() == 1) {
        colorSpace = CGColorSpaceCreateDeviceGray();
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    
    // Creating CGImage from cv::Mat
    CGImageRef imageRef = CGImageCreate(cvMat.cols,                                 //width
                                        cvMat.rows,                                 //height
                                        8,                                          //bits per component
                                        8 * cvMat.elemSize(),                       //bits per pixel
                                        cvMat.step[0],                              //bytesPerRow
                                        colorSpace,                                 //colorspace
                                        kCGImageAlphaLast|kCGBitmapByteOrderDefault,// bitmap info
                                        provider,                                   //CGDataProviderRef
                                        NULL,                                       //decode
                                        false,                                      //should interpolate
                                        kCGRenderingIntentDefault                   //intent
                                        );
    
    
    // Getting UIImage from CGImage
    UIImage *finalImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    
    return finalImage;
}

+ (UIImage *)cannyEdges:(UIImage *)image threshold:(int)threshold thickness:(int)thickness;
{
    Mat src = [OpenCVWrapper cvMatFromUIImage:image];
    Mat src_gray;
    cvtColor(src, src_gray, CV_BGR2GRAY);
    
    Mat detected_edges;
    int sigma = max(src.rows, src.cols) / 512.0 * 3 + 0.5;
    blur(src_gray, detected_edges, cv::Size(sigma, sigma));
    
    /// Canny detector
    Canny(detected_edges, detected_edges, threshold, threshold * 3, 3);

    Mat white(src.rows, src.cols, CV_8UC4, cv::Scalar(255, 255, 255, 255));
    Mat dst(src.rows, src.cols, CV_8UC4, cv::Scalar(0, 0, 0, 0));
    white.copyTo(dst, detected_edges);
    
    if (thickness > 0) {
        Mat dst2(src.rows, src.cols, CV_8UC4, cv::Scalar(0, 0, 0, 0));
        unsigned char *input = (unsigned char*)(dst.data);
        unsigned char *output = (unsigned char*)(dst2.data);
        for (int j = 0; j < dst.rows; j++){
            for (int i = 0; i < dst.cols; i++) {
                if (input[dst.step * j + i * 4 + 3] != 0)
                {
                    for (int jj = max(j - thickness, 0); jj < min(j + thickness + 1, dst.rows); jj++)
                    {
                        for (int ii = max(i - thickness, 0); ii < min(i + thickness + 1, dst.cols); ii++)
                        {
                            for (int p = 0; p < 4; p++)
                            {
                                output[dst.step * jj + ii * 4 + p] = input[dst.step * j + i * 4 + p];
                            }
                        }
                    }
                }
            }
        }
        dst = dst2;
    }
    
    return [OpenCVWrapper UIImageFromCVMat:dst];
}

@end
