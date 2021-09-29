
/// imageMode
enum UIImageContentMode {
    case scaleToFill
    case scaleAspectFit
    case scaleAspectFill
}

extension UIImage {
    /// 调整图片大小
    /// - Parameters:
    ///   - toSize: 目标大小
    ///   - contentMode: 内容模式
    func resize(toSize: CGSize, contentMode: UIImageContentMode = .scaleToFill) -> UIImage? {
        let horizontalRatio = size.width / self.size.width
        let verticalRatio = size.height / self.size.height
        var ratio: CGFloat!
        
        switch contentMode {
        case .scaleToFill:
            ratio = 1
        case .scaleAspectFill:
            ratio = max(horizontalRatio, verticalRatio)
        case .scaleAspectFit:
            ratio = min(horizontalRatio, verticalRatio)
        }
        
        let rect = CGRect(x: 0, y: 0, width: size.width * ratio, height: size.height * ratio)
        
        // Fix for a colorspace / transparency issue that affects some types of
        // images. See here: http://vocaro.com/trevor/blog/2009/10/12/resize-a-uiimage-the-right-way/comment-page-2/#comment-39951
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        let context = CGContext(data: nil, width: Int(rect.size.width), height: Int(rect.size.height), bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace, bitmapInfo: bitmapInfo.rawValue)
        
        let transform = CGAffineTransform.identity
        
        // Rotate and/or flip the image if required by its orientation
        context?.concatenate(transform)
        
        // Set the quality level to use when rescaling
        context!.interpolationQuality = CGInterpolationQuality(rawValue: 3)!
        
        // CGContextSetInterpolationQuality(context, CGInterpolationQuality(kCGInterpolationHigh.value))
        
        // Draw into the context; this scales the image
        context?.draw(self.cgImage!, in: rect)
        
        // Get the resized image from the context and a UIImage
        let newImage = UIImage(cgImage: (context?.makeImage()!)!, scale: self.scale, orientation: self.imageOrientation)
        return newImage
    }
    
    
    /// 压缩图片
    /// - Parameter boundary: 压缩边的大小
    /// - Returns: Data
    func compression(boundary: CGFloat = 1280) -> Data? {
        let size = imageSize(boundary: boundary)
        let reImage = resizedImage(size)
        let data = reImage?.jpegData(compressionQuality: 0.5)
        return data
    }
    
    func imageSize(boundary: CGFloat = 1280) -> CGSize {
        var width = self.size.width
        var height = self.size.height
        
        if (width < boundary && height < boundary) {
            return CGSize(width: width, height: height)
        }
        
        let ratio = CGFloat(max(width, height) / min(width, height))
        if ratio <= 2 {
            let x = CGFloat(max(width, height) / boundary)
            if width > height {
                width = boundary
                height = height / x
            } else {
                height = boundary
                width = width / x
            }
        } else {
            // width, height > 1280
            if min(width, height) >= boundary {
                // Set the smaller value to the boundary, and the larger value is compressed
                let x = CGFloat(min(width, height) / boundary)
                if width < height {
                    width = boundary
                    height = height / x
                } else {
                    height = boundary
                    width = width / x
                }
            }
        }
        
        return CGSize(width: width, height: height)
    }
    
    // 将图片缩放到指定大小
    func resizedImage(_ newSize: CGSize) -> UIImage? {
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)

        //***重新计算区域 把小数点格式化掉 防止出现白边***
        var newRect = CGRect.zero
        //向下取整
        newRect.origin.x = CGFloat(ceilf(Float(rect.origin.x)))
        newRect.origin.y = CGFloat(ceilf(Float(rect.origin.y)))
        //向上取整
        newRect.size.width = CGFloat(floorf(Float(rect.size.width)))
        newRect.size.height = CGFloat(floorf(Float(rect.size.height)))
        //获取小数点后面的数
        let leftMargin: CGFloat = newRect.origin.x - rect.origin.x
        let rightMargin: CGFloat = rect.size.width - newRect.size.width
        let topMargin: CGFloat = newRect.origin.y - rect.origin.y
        let bottomMargin: CGFloat = rect.size.height - newRect.size.height

        //重新计算宽高
        newRect.size.width = CGFloat(floorf(Float(rect.size.width - (leftMargin + rightMargin))))
        newRect.size.height = CGFloat(floorf(Float(rect.size.height - (topMargin + bottomMargin))))
        UIGraphicsBeginImageContext(newRect.size)
        var newImage: UIImage? = nil
        if let cgImage = cgImage {
            newImage = UIImage(cgImage: cgImage, scale: scale, orientation: imageOrientation)
        }
        newImage?.draw(in: newRect)
        newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }
}
