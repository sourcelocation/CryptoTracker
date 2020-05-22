//
//  Graph.swift
//  CryptoTracker
//
//  Created by iMac on 20.05.2020.
//  Copyright © 2020 iMac. All rights reserved.
//

import UIKit

class Graph:UIView {
    var yPositions:[Double]?
    override func draw(_ rect: CGRect) {
        let aPath = UIBezierPath()
        
        if yPositions != nil, yPositions?.count != 0  {
            aPath.move(to: CGPoint(x:1, y: 256 - yPositions!.first!))
            let distanceBetweenPoints = Double(self.frame.size.width) / Double(yPositions!.count)
            var currentX = 1.0
            for yPos in yPositions! {
                currentX += distanceBetweenPoints
                aPath.addLine(to: CGPoint(x:currentX, y:256.0 - yPos))
            }
            
            UIColor.red.set()
            aPath.stroke()
            aPath.lineWidth = 5
            //If you want to fill it as well
        }
    }
}
