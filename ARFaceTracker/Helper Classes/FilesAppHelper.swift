//
//  FilesAppManager.swift
//  ARFaceTrackingSwift4
//
//  Created by Kieran Armstrong on 2020-05-13.
//  Copyright © 2020 Kieran Armstrong. All rights reserved.
//

import Foundation
import UIKit

class FilesAppHelper: UIViewController {
    
    
    static var app: FilesAppHelper = {
        return FilesAppHelper()
    }()
    
    func saveData(fileName: String, ext: String, data: Data) {
        let file = fileName + ext
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = dir.appendingPathComponent(file)
        
        do {
            try data.write(to: fileURL)
            print("File saved")
        }
        catch {
            print("Error \(error)")
        }
    }
    
    func saveImageAsJPEG (fileName: String, img: UIImage) {
        if let data = img.jpegData(compressionQuality: 0) {
            let file = fileName + ".jpg"
            let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let fileURL = dir.appendingPathComponent(file)
            
            try? data.write(to: fileURL)
        }
    }
    
    func saveString(fileName: String, ext: String, data: String) {
        let file = fileName + ext
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = dir.appendingPathComponent(file)
        
        do {
            try data.write(to: fileURL, atomically: false, encoding: .utf8)
            print("File saved")
        }
        catch {
            print("Error \(error)")
        }
    }
    
    func importFile() {
//        let documentPicker = UIDocumentPickerViewController(documentTypes: [kUTTypeStereolithography as String], in: .import)
//        let pVc = UIApplication.getPresentedViewController()
//        documentPicker.delegate = self
//        documentPicker.allowsMultipleSelection = false
//
//        DispatchQueue.main.async {
//            pVc!.present(documentPicker, animated: true, completion: nil)
//        }
    }
}

extension FilesAppHelper: UIDocumentPickerDelegate {
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let selectedFileURL = urls.first else {
            return
        }
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let sandBoxFileURL = dir.appendingPathComponent(selectedFileURL.lastPathComponent)
        
        if (FileManager.default.fileExists(atPath: sandBoxFileURL.path)) {
            print ("File already exists!!!")
        } else {
            do {
                try FileManager.default.copyItem(at: selectedFileURL, to: sandBoxFileURL)
            }
            catch {
                
            }
        }
    }
}

extension UIApplication{
class func getPresentedViewController() -> UIViewController? {
    var presentViewController = UIApplication.shared.windows.filter{$0.isKeyWindow}.first!.rootViewController
    while let pVC = presentViewController?.presentedViewController
    {
        presentViewController = pVC
    }

    return presentViewController
  }
}
