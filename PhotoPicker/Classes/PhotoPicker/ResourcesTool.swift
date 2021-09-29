//
// ResourcesManger.swift
// PhotoPicker
//
// Created by raohongping on 2021/9/14.
// 
//

public class ResourcesTool {
    
    static var bundle: Bundle = {
        let bundle = Bundle.init(path: Bundle.init(for: ResourcesTool.self).path(forResource: "PhotoPicker", ofType: "bundle", inDirectory: nil)!)
        return bundle!
    }()
    
    public static func getBundleImg(named name: String) -> UIImage? {
        
        guard let image = UIImage(named: name, in: bundle, compatibleWith: nil) else {
            return nil
        }
        
        return image
    }
}
