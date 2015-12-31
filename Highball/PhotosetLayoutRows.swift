//
//  PhotosetLayoutRows.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 1/1/16.
//  Copyright © 2016 ianynda. All rights reserved.
//

import Foundation

struct PhotosetLayoutRows {
    let layoutRows: [Int]

    init(photos: [PostPhoto], layoutString: String?) {
        if let layoutString = layoutString {
            var photosetLayoutRows = Array<Int>()
            for character in layoutString.characters {
                photosetLayoutRows.append(Int("\(character)")!)
            }
            self.layoutRows = photosetLayoutRows
        } else if photos.count == 0 {
            self.layoutRows = []
        } else if photos.count % 2 == 0 {
            var layoutRows: [Int] = []
            for _ in 0...photos.count/2-1 {
                layoutRows.append(2)
            }
            self.layoutRows = layoutRows
        } else if photos.count % 3 == 0 {
            var layoutRows: [Int] = []
            for _ in 0...photos.count/3-1 {
                layoutRows.append(3)
            }
            self.layoutRows = layoutRows
        } else {
            var layoutRows: [Int] = []
            for _ in 0...photos.count-1 {
                layoutRows.append(1)
            }
            self.layoutRows = layoutRows
        }
    }
}
