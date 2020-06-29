//
//  SourceEditorCommand.swift
//  XcodeBoss Comments
//
//  Created by Kim Ahlberg on 2017-05-14.
//  Copyright © 2017 The Evil Boss. All rights reserved.
//

import Foundation
import XcodeKit

class SourceEditorCommand: NSObject, XCSourceEditorCommand {
	
    func perform(with invocation: XCSourceEditorCommandInvocation, completionHandler: @escaping (Error?) -> Void ) -> Void {

        // Implement the command here, invoking the completion handler when done. Pass it nil on success, and an NSError on failure.

		// Read the preferred line length/break column from persisted storage.
		let preferredBreakColumn = self.getPreferredBreakColumn()
		let minimumCommentLengthPerLine = 16

        #if DEBUG
            print("Extension invoked w UTI '\(invocation.buffer.contentUTI)'. Preferred break column \(preferredBreakColumn).")
        #endif
                
        // The invocation.buffer.selections array contains at least one XCSourceTextRange.
        // Break the line at the whitespace closest before the decided line length, adding spaces or tabs+spaces (as described in invocation parameter) to pad the next line before inserting "// ".
        // Use buffer.tabWidth, buffer.indentationWidth and buffer.usesTabsForIndendation.
        
        // Bail out if more than one selection. TODO: Perhaps handle all comment lines in all selections instead?
        if invocation.buffer.selections.count > 1 {
            
            completionHandler(nil) // Perhaps provide an Error?
            NSLog("Exited: More than one selection.")
            return;
        }
        
        // Bail out if the only selection contains more than one line.
        let selectionRange:XCSourceTextRange = invocation.buffer.selections.firstObject as! XCSourceTextRange
        if selectionRange.start.line != selectionRange.end.line {
            
            if selectionRange.end.line == selectionRange.start.line + 1 && selectionRange.end.column == 0 {
                
                #if DEBUG
                    print("Note: Selection is not a single line, but second line has no charcters in selection so we go ahead anyway.")
                #endif
            } else {
                
                completionHandler(nil) // Perhaps provide an Error?
                NSLog("Exited: Selection is not a single line.")
                return;
            }
        }
        
        var lineIndex = selectionRange.start.line;
        let theLine:String = invocation.buffer.lines[lineIndex] as! String
        #if DEBUG
            print("Line: %@", theLine)
        #endif
		
		// Find the column index for where the first comment on the line starts.
        guard let commentStartIndex = self.getCommentStartColumnIndex(for: theLine, tabWidth: invocation.buffer.tabWidth) else {
					
			completionHandler(nil) // Perhaps provide an Error?
			NSLog("Exited: Line doesn't contain a code comment.")
			return;
		}
		
        #if DEBUG
            print("First comment at Index \(commentStartIndex)")
        #endif
		
		let commentLinePrefix = self.getCommentPrefix(for: theLine)
		
        // Make sure there's a sensible amount of comment characters per line.
        var breakColumn = preferredBreakColumn; // Default break column to use if no need to adapt.
        if commentStartIndex > breakColumn - minimumCommentLengthPerLine {
            
            breakColumn = commentStartIndex + minimumCommentLengthPerLine
        }
        #if DEBUG
            print("Adapted break column: \(breakColumn).")
        #endif

        // Create the prefix, with sufficient whitespace and then "// " or "/// ".
        var newLinePrefix = ""

		var prefixInteger = 0;

        // If using tabs, insert sufficient number of tabs.
        if invocation.buffer.usesTabsForIndentation {
            
            let nrOfTabs = commentStartIndex/invocation.buffer.tabWidth
            for _ in prefixInteger ..< nrOfTabs {
                
                newLinePrefix.append("\t")
            }
            
            prefixInteger += nrOfTabs * invocation.buffer.tabWidth
		}
		
        // Add the remaining number of spaces.
        for _ in prefixInteger ..< commentStartIndex {
            
            newLinePrefix.append(" ")
        }
        newLinePrefix.append(commentLinePrefix)
        
        // Add words until newLine.charcters.count >= breakColumn, then remove last word unless only one word.
        let newLines: NSMutableArray = []
        var newLine: String = ""
        var lastWord: String = ""
		
		var tabReplacementSpaces = "" // Variable to hold a string w. the number of spaces equivalent to a tab.
		for _ in 0 ..< invocation.buffer.tabWidth {
			tabReplacementSpaces.append(" ")
		}
		
        for character in theLine {

			let newLineWithoutTabs = newLine.replacingOccurrences(of: "\t", with: tabReplacementSpaces)
			let currentColumn = newLineWithoutTabs.count
			
            if currentColumn > breakColumn {
				
                // Remove last word, unless only one word after the "// ".
                let charactersToRemove: Int = lastWord.count
                let lastWordRange =  newLine.index(newLine.endIndex, offsetBy: -charactersToRemove )..<newLine.endIndex
                newLine.removeSubrange(lastWordRange)
                
                // Store the new line to the array, unless it only contains the commentLinePrefix.
                if newLine != newLinePrefix {
                    
                    // Remove the ending characters, which is always a whitespace.
                    newLine.removeLast()
                    newLines.add(newLine)
                }
                
                newLine = newLinePrefix + lastWord // Start a new line with the comment prefix.
            }
            
            lastWord.append(character)
            // Reset lastWord if it contains a whitespace.
            if let _ = lastWord.rangeOfCharacter(from: CharacterSet.whitespaces) {
                lastWord = ""
            }
			
			// Append the character and update the column index with the character width.
            newLine.append(character)
        }
        
        if !newLine.isEmpty {
            
            newLines.add(newLine) // Store the final new line to the array.
        }
        
        #if DEBUG
            print("All new lines: \(newLines)")
        #endif
        
        // Remove the original line...
        invocation.buffer.lines.removeObject(at: lineIndex)
        // ... and insert ALL the new lines, starting at the same index.
        for line in newLines {
            
            // Ignore line if it only contains the commentLinePrefix
            var lineStr = line as! String
            lineStr = lineStr.trimmingCharacters(in: CharacterSet.newlines)
            if lineStr == newLinePrefix {
                continue
            }
            
            invocation.buffer.lines.insert(lineStr, at: lineIndex)
            lineIndex += 1
        }
        
        completionHandler(nil)
    }
	
	/// Reads the preferred break column from the UserDefaults, or returns a sensible default.
	func getPreferredBreakColumn() -> Int {
		
		var preferredBreakColumn = 120 // Default to 120 in case there is nothing stored in the UserDefaults.
		
		if let defaults : UserDefaults = UserDefaults.init(suiteName: APP_GROUP_SUITE_NAME) {
			
			let lineLength = defaults.integer(forKey: LINE_LENGTH_KEY)
			
			if lineLength > 0 {
				
				preferredBreakColumn = lineLength
			} else {
				
				NSLog("Unable to read preferred break column from the UserDefaults, defaulting to \(preferredBreakColumn).")
			}
		}

		return preferredBreakColumn
	}
	
	/// Returns the column index of the start of the first comment in the text, or nil if no comment found.
	func getCommentStartColumnIndex(for text : String, tabWidth : Int) -> Int? {
		
		if !text.contains("//") {
			
			return nil // The text doesn't contain a comment.
		}
		
		var commentStartIndex = 0;
		var lastCharacter: Character = " "
		for character in text {
			
			if character == "/" && lastCharacter == "/" {
				
				commentStartIndex -= 1 // Subtract one since we want the index for the previous "/"
				break;
			}
			
			lastCharacter = character
			
			// Increment the index by one, or by the tab width the character is a tab.
			if character == "\t" {
				commentStartIndex += tabWidth
			} else {
				commentStartIndex += 1
			}
		}
		
		return commentStartIndex
	}
	
	/// Returns the prefix used for comments in the text, either // or ///.
	func getCommentPrefix(for text : String) -> String {
		
		var commentLinePrefix = "// " // Default value.
		
		// See if there is a triple slash with the same starting index as a double slash. 
		// In which case the comment prefix is a triple slash.
		if let rangeOfCommentStart = text.range(of: "//") {
			
			if let rangeOfTripleSlashCommentStart = text.range(of: "///") {
				
				if rangeOfTripleSlashCommentStart.lowerBound == rangeOfCommentStart.lowerBound {
					
					// The comment is a triple slash, so use that as prefix.
					commentLinePrefix = "/// "
				}
			}
		}
		
		return commentLinePrefix
	}
}
