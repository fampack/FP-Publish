//
//  UIImage.swift
//  FP
//
//  Created by Bajrang on 20/08/18.
//  Copyright © 2018 Bajrang. All rights reserved.
//

import Foundation
import UIKit

extension UIImage
{
    func scaleAndRotateImage() -> UIImage
    {
        let kMaxResolution: CGFloat = 1020
        
        let imgRef = self.cgImage! as CGImage
        let width: CGFloat = CGFloat(imgRef.width)
        let height: CGFloat = CGFloat(imgRef.height)
        var transform: CGAffineTransform = CGAffineTransform.identity
        var bounds = CGRect(x: 0, y: 0, width: width, height: height)
        if width > kMaxResolution || height > kMaxResolution {
            let ratio: CGFloat = width / height
            if ratio > 1 {
                bounds.size.width = kMaxResolution
                bounds.size.height = bounds.size.width / ratio
            }
            else {
                bounds.size.height = kMaxResolution
                bounds.size.width = bounds.size.height * ratio
            }
        }
        let scaleRatio: CGFloat = bounds.size.width / width
        let imageSize = CGSize(width: imgRef.width, height: imgRef.height)
        var boundHeight: CGFloat
        let orient: UIImage.Orientation = self.imageOrientation
        switch orient {
        case .up:
            //EXIF = 1
            transform = CGAffineTransform.identity
        case .upMirrored:
            //EXIF = 2
            transform = CGAffineTransform(translationX: imageSize.width, y: 0.0)
            transform = transform.scaledBy(x: -1.0, y: 1.0)
        case .down:
            //EXIF = 3
            transform = CGAffineTransform(translationX: imageSize.width, y: imageSize.height)
            transform = transform.rotated(by: .pi)
        case .downMirrored:
            //EXIF = 4
            transform = CGAffineTransform(translationX: 0.0, y: imageSize.height)
            transform = transform.scaledBy(x: 1.0, y: -1.0)
        case .leftMirrored:
            //EXIF = 5
            boundHeight = bounds.size.height
            bounds.size.height = bounds.size.width
            bounds.size.width = boundHeight
            transform = CGAffineTransform(translationX: imageSize.height, y: imageSize.width)
            transform = transform.scaledBy(x: -1.0, y: 1.0)
            transform = transform.rotated(by: 3.0 * .pi / 2.0)
        case .left:
            //EXIF = 6
            boundHeight = bounds.size.height
            bounds.size.height = bounds.size.width
            bounds.size.width = boundHeight
            transform = CGAffineTransform(translationX: 0.0, y: imageSize.width)
            transform = transform.rotated(by: 3.0 * .pi / 2.0)
        case .rightMirrored:
            //EXIF = 7
            boundHeight = bounds.size.height
            bounds.size.height = bounds.size.width
            bounds.size.width = boundHeight
            transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
            transform = transform.rotated(by: .pi / 2.0)
        case .right:
            //EXIF = 8
            boundHeight = bounds.size.height
            bounds.size.height = bounds.size.width
            bounds.size.width = boundHeight
            transform = CGAffineTransform(translationX: imageSize.height, y: 0.0)
            transform = transform.rotated(by: .pi / 2.0)
        default:
            let exception = NSException(name:.internalInconsistencyException, reason:"invalid image resolution", userInfo:nil)
            exception.raise()
        }
        UIGraphicsBeginImageContext(bounds.size)
        let context: CGContext? = UIGraphicsGetCurrentContext()
        if orient == .right || orient == .left {
            context?.scaleBy(x: -scaleRatio, y: scaleRatio)
            context?.translateBy(x: -height, y: 0)
        }
        else {
            context?.scaleBy(x: scaleRatio, y: -scaleRatio)
            context?.translateBy(x: 0, y: -height)
        }
        context?.concatenate(transform)
        UIGraphicsGetCurrentContext()?.draw(imgRef, in: CGRect(x: 0, y: 0, width: width, height: height))
        let imageCopy = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return imageCopy ?? UIImage()
    }
}

extension UITableView
{
    func indexPath(forItem: AnyObject) -> IndexPath?
    {
        let itemPosition: CGPoint = forItem.convert(CGPoint.zero, to: self)
        return self.indexPathForRow(at: itemPosition)
    }
}

extension Notification.Name {
    static public let imagePickerPresented = Notification.Name("com.fp.imagePickerPresented")
}
