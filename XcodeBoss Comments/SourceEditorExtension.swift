//
//  SourceEditorExtension.swift
//  XcodeBoss Comments
//
//  Created by Kim Ahlberg on 2017-05-14.
//  Copyright © 2017 The Evil Boss. All rights reserved.
//

import Foundation
import XcodeKit

class SourceEditorExtension: NSObject, XCSourceEditorExtension {
    
    
    func extensionDidFinishLaunching() {
         // If your extension needs to do any work at launch, implement this optional method.
        
        #if DEBUG
            print("Extension did finish launching")
        #endif
    }
 
    
    /*
    var commandDefinitions: [[XCSourceEditorCommandDefinitionKey: Any]] {
        // If your extension needs to return a collection of command definitions that differs from those in its Info.plist, implement this optional property getter.
        return []
    }
    */
    
}
