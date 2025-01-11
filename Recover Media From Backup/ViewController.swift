//
//  ViewController.swift
//  Recover Media From Backup
//
//  Created by Sandeep Rana on 14/01/22.
//

import Cocoa
import Foundation
import FileProvider

class ViewController: NSViewController {
    
    
    @IBOutlet weak var lStatus:NSTextField!
    

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    var pathSelected:String?
    
    @IBAction func onClickBackupPath(_ sender: NSButton) {
        let dialog = NSOpenPanel();

        dialog.title                   = "Choose a file| Our Code World";
        dialog.showsResizeIndicator    = true;
        dialog.showsHiddenFiles        = false;
        dialog.allowsMultipleSelection = false;
        dialog.canChooseDirectories = true;
        dialog.canChooseFiles = false;

        if (dialog.runModal() ==  NSApplication.ModalResponse.OK) {
            let result = dialog.url // Pathname of the file

            if (result != nil) {
                let path: String = result!.path
                self.pathSelected = result?.path
                self.iterateThroughFilesAndFolderAt(path:path);
            }
            
        } else {
            // User clicked on "Cancel"
            return
        }
    }
    
    @IBAction func onClickBackupPathForWhatsapp(_ sender: NSButton) {
        let dialog = NSOpenPanel();

        dialog.title                   = "Choose a file| Our Code World";
        dialog.showsResizeIndicator    = true;
        dialog.showsHiddenFiles        = false;
        dialog.allowsMultipleSelection = false;
        dialog.canChooseDirectories = true;
        dialog.canChooseFiles = false;

        if (dialog.runModal() ==  NSApplication.ModalResponse.OK) {
            let result = dialog.url // Pathname of the file

            if (result != nil) {
                let path: String = result!.path
                self.pathSelected = result?.path
                self.iterateThroughFilesAndFolderAtForWhatsapp(path:path);
            }
            
        } else {
            // User clicked on "Cancel"
            return
        }
    }
    
    
    func iterateThroughFilesAndFolderAt(path:String)  {
        do {
            let allPaths = try FileManager.default.contentsOfDirectory(atPath: path)
            var isDir:ObjCBool = false
            for item in allPaths {
                let fullPath = "\(path)/\(item)"
                if FileManager.default.fileExists(atPath: fullPath, isDirectory: &isDir) {
                    if isDir.boolValue {
                        iterateThroughFilesAndFolderAt(path: fullPath)
                    }else {
                        self.checkIfFileIsMedia(filePath:fullPath, currentName:item)
                    }
                }else {
                    print("File Doesn't exist: \(fullPath)");
                }
            }
            
            self.lStatus.stringValue = "Done"
            
        }catch let error {
            print(error.localizedDescription)
        }
        print("Process Completed!")
    }
    
    func iterateThroughFilesAndFolderAtForWhatsapp(path:String)  {
        do {
            let allPaths = try FileManager.default.contentsOfDirectory(atPath: path)
            var isDir:ObjCBool = false
            for item in allPaths {
                let fullPath = "\(path)/\(item)"
                if FileManager.default.fileExists(atPath: fullPath, isDirectory: &isDir) {
                    if isDir.boolValue {
                        iterateThroughFilesAndFolderAtForWhatsapp(path: fullPath)
                    }else {
                        self.checkExtensionType(filePath:fullPath, currentName:item)
                    }
                }else {
                    print("File Doesn't exist: \(fullPath)");
                }
            }
            
            self.lStatus.stringValue = "Done"
            
        }catch let error {
            print(error.localizedDescription)
        }
        print("Process Completed!")
    }
    
    
    func checkExtensionType(filePath:String, currentName:String){
        let split = currentName.split(separator: ".");
        if split.count > 1 {
            let extFile = String(describing:split.last)
            if let path = self.pathSelected {
                do {
                    let dirPath = "\(path)/Recovery/\(extFile)/"
                    
                    try FileManager.default.createDirectory(at: URL(fileURLWithPath: dirPath), withIntermediateDirectories: true, attributes: [:]);
                    
                    let urlTo = URL(fileURLWithPath: "\(dirPath)/\(currentName)")
                    try FileManager.default.copyItem(at: URL(fileURLWithPath: filePath), to:urlTo)
                    self.lStatus.stringValue = "Updating File: \(currentName)"
                }catch let error {
                    print(error.localizedDescription)
                }
            }
        }
    }
    
    
    func checkIfFileIsMedia(filePath:String, currentName:String) {
        let handle = FileHandle(forReadingAtPath: filePath)
        do {
            let dataFirstByte = try handle?.read(upToCount: 1)
            let mime = dataFirstByte?.mime
            
            if let path = self.pathSelected {
                let dirPath = "\(path)/Recovery/\(mime?.type.rawValue ?? "unknown")/"
                let urlTo = URL(fileURLWithPath: "\(dirPath)\(currentName).\(mime?.mimeExtension ?? ".\(dataFirstByte?.hexString ?? "nohex").unknown")")
                
                try FileManager.default.createDirectory(at: URL(fileURLWithPath: dirPath), withIntermediateDirectories: true, attributes: [:]);
                
                try FileManager.default.copyItem(at: URL(fileURLWithPath: filePath), to:urlTo)
                self.lStatus.stringValue = "Updating File: \(currentName)"
            }else {
                print("Error: Couldn't copy file \(filePath)")
                self.lStatus.stringValue = "Error File: \(currentName)"
            }
//            print("\(currentName):",dataFirstByte?.mime?.mimeString, dataFirstByte?.hexString)
            try handle?.close();
        }catch let error {
            print(error)
            try? handle?.close();
        }
        
        
    }

}

struct MimeType {
    var hex:UInt16;
    var mimeString:String
    var mimeExtension:String
    var type:FileType
}

enum FileType:String {
    case image,video,archive,audio,unknown,document,application,database,tcpdump
}

extension Data {
    
    
    private static let mimeTypeSignatures: [UInt8: MimeType] = [
        0xFF: MimeType(hex: 0xFF, mimeString: "image/jpeg", mimeExtension: "jpeg", type: .image),
        0x89: MimeType(hex: 0x89, mimeString: "image/png", mimeExtension: "png", type: .image),
        0x66: MimeType(hex: 0x66, mimeString: "video/mp4", mimeExtension: "mp4", type: .video),
        0x00: MimeType(hex: 0x00, mimeString: "video/mp4", mimeExtension: "mp4", type: .video),
        0x47: MimeType(hex: 0x47, mimeString: "image/gif", mimeExtension: "gif", type: .image),
        0x49: MimeType(hex: 0x49, mimeString: "image/tiff", mimeExtension: "tiff", type: .image),
        0x4D: MimeType(hex: 0x4D, mimeString: "image/tiff", mimeExtension: "tiff", type: .image),
        0x25: MimeType(hex: 0x25, mimeString: "application/pdf", mimeExtension: "pdf", type: .document),
        0xD0: MimeType(hex: 0xD0, mimeString: "application/vnd", mimeExtension: "vnd", type: .application),
        0x46: MimeType(hex: 0x46, mimeString: "text/plain", mimeExtension: "txt", type: .document),
        0x37: MimeType(hex: 0x37, mimeString: "application/zip", mimeExtension: "zip", type: .document),
        0x75: MimeType(hex: 0x75, mimeString: "application/zip", mimeExtension: "zip", type: .document),
        0x60: MimeType(hex: 0x60, mimeString: "application/arj", mimeExtension: "arj", type: .document),
        0x3C: MimeType(hex: 0x3C, mimeString: "application/xml", mimeExtension: "xml", type: .document),
        0x62: MimeType(hex: 0x62, mimeString: "application/plist", mimeExtension: "xml", type: .document),
        0x53: MimeType(hex: 0x53, mimeString: "application/sqlite", mimeExtension: "db", type: .database),
        0x7B: MimeType(hex: 0x7B, mimeString: "application/rtf", mimeExtension: "rtf", type: .document),
        0x34: MimeType(hex: 0x34, mimeString: "application/pcap", mimeExtension: "pcap", type: .tcpdump),
    ]
    
    var mimeString: String {
        var c: UInt8 = 0
        copyBytes(to: &c, count: 1)
        return Data.mimeTypeSignatures[c]?.mimeString ?? "\(c)_application/octet-stream"
    }
    
    var rawHex: UInt8 {
        var c: UInt8 = 0
        copyBytes(to: &c, count: 1)
        return c
    }
    
    var hexString:String {
        return String(format: "%02X",self.rawHex);
    }
    
    
    
    var mime: MimeType? {
        var c: UInt8 = 0
        copyBytes(to: &c, count: 1)
        return Data.mimeTypeSignatures[c]
    }
}

