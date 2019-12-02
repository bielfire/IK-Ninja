/**
 Copyright (c) 2016 Razeware LLC
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 */

import SpriteKit

class GameScene: SKScene {
    
    // MRK: - Properties
    
    var shadow: SKNode!
    var lowerTorso: SKNode!
    var upperTorso: SKNode!
    var upperArmFront: SKNode!
    var lowerArmFront: SKNode!
    var fistFront: SKNode!
    var upperArmBack: SKNode!
    var lowerArmBack: SKNode!
    var fistBack: SKNode!
    var rightPunch = true
    var head: SKNode!
    var firstTouch = false
    var lastSpawnTimeInterval: TimeInterval = 0
    var lastUpdateTimeInterval: TimeInterval = 0
    let upperArmAngleDeg: CGFloat = -10
    let lowerArmAngleDeg: CGFloat = 130
    let targetNode = SKNode()
    
    // MARK: - Override
    
    override func didMove(to view: SKView) {
        let rotationConstraintArm = SKReachConstraints(lowerAngleLimit: CGFloat(0), upperAngleLimit: CGFloat(160))
        lowerTorso = childNode(withName: "torso_lower")
        lowerTorso.position = CGPoint(x: frame.midX, y: frame.midY - 30)
        
        shadow  = childNode(withName: "shadow")
        shadow.position = CGPoint(x: frame.midX, y: frame.midY - 100)
        
        upperTorso = lowerTorso.childNode(withName: "torso_upper")
        upperArmFront = upperTorso.childNode(withName: "arm_upper_front")
        lowerArmFront = upperArmFront.childNode(withName: "arm_lower_front")
        
        fistFront = lowerArmFront.childNode(withName: "fist_front")
        lowerArmFront.reachConstraints = rotationConstraintArm
        
        upperArmBack = upperTorso.childNode(withName: "arm_upper_back")
        lowerArmBack = upperArmBack.childNode(withName: "arm_lower_back")
        
        fistBack = lowerArmBack.childNode(withName: "fist_back")
        lowerArmBack.reachConstraints = rotationConstraintArm
        
        head = upperTorso.childNode(withName: "head")
        
        
        let orientToNodeConstraint = SKConstraint.orient(to: targetNode, offset: SKRange(constantValue: 0.0))
        let range = SKRange(lowerLimit: CGFloat(-50).degreesToRadians(),
                            upperLimit: CGFloat(80).degreesToRadians())
        let rotationConstraint = SKConstraint.zRotation(range)
        rotationConstraint.enabled = false
        orientToNodeConstraint.enabled = false
        head.constraints = [orientToNodeConstraint, rotationConstraint]
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if !firstTouch {
            for c in head.constraints! {
                let constraint = c
                constraint.enabled = true
            }
            
            firstTouch = true
        }
        
        for touch: AnyObject in touches {
            let location = touch.location(in: self)
            lowerTorso.xScale =
                location.x < frame.midX ? abs(lowerTorso.xScale) * -1 : abs(lowerTorso.xScale)
            punchAt(location)
            targetNode.position = location
        }
    }
    
    // MARK: - Methods
    
    func punchAt(_ location: CGPoint, upperArmNode: SKNode, lowerArmNode: SKNode, fistNode: SKNode) {
        let punch = SKAction.reach(to: location, rootNode: upperArmNode, duration: 0.1)
        let restore = SKAction.run {
            let rotateActionA = SKAction.rotate(toAngle: self.upperArmAngleDeg.degreesToRadians(), duration: 0.1)
            let rotateActionB = SKAction.rotate(toAngle: self.lowerArmAngleDeg.degreesToRadians(), duration: 0.1)
            upperArmNode.run(rotateActionA)
            lowerArmNode.run(rotateActionB)
        }
        
        let checkIntersection = intersectionCheckAction(for: fistNode)
        fistNode.run(SKAction.sequence([punch, checkIntersection, restore]))
    }
    
    func punchAt(_ location: CGPoint) {
        if rightPunch {
            punchAt(location, upperArmNode: upperArmFront, lowerArmNode: lowerArmFront, fistNode: fistFront)
        }
            
        else {
            punchAt(location, upperArmNode: upperArmBack, lowerArmNode: lowerArmBack, fistNode: fistBack)
        }
        
        rightPunch = !rightPunch
    }
    
    func addShuriken() {
        let shuriken = SKSpriteNode(imageNamed: "projectile")
        
        let minY = lowerTorso.position.y - 60 + shuriken.size.height/2
        let maxY = lowerTorso.position.y  + 140 - shuriken.size.height/2
        let rangeY = maxY - minY
        let actualY = CGFloat(arc4random()).truncatingRemainder(dividingBy: rangeY) + minY
        
        let left = arc4random() % 2
        let actualX = (left == 0) ? -shuriken.size.width/2 : size.width + shuriken.size.width/2
        
        shuriken.position = CGPoint(x: actualX, y: actualY)
        shuriken.name = "shuriken"
        shuriken.zPosition = 1
        addChild(shuriken)
        
        let minDuration = 4.0
        let maxDuration = 6.0
        let rangeDuration = maxDuration - minDuration
        let actualDuration = Double(arc4random()).truncatingRemainder(dividingBy: rangeDuration) + minDuration
        
        let actionMove = SKAction.move(to: CGPoint(x: size.width/2, y: actualY), duration: actualDuration)
        let actionMoveDone = SKAction.removeFromParent()
        shuriken.run(SKAction.sequence([actionMove, actionMoveDone]))
        
        let angle = left == 0 ? CGFloat(-90).degreesToRadians() : CGFloat(90).degreesToRadians()
        let rotate = SKAction.repeatForever(SKAction.rotate(byAngle: angle, duration: 0.2))
        shuriken.run(SKAction.repeatForever(rotate))
    }
    
    func updateWithTimeSinceLastUpdate(timeSinceLast: CFTimeInterval) {
        lastSpawnTimeInterval = timeSinceLast + lastSpawnTimeInterval
        if lastSpawnTimeInterval > 0.75 {
            lastSpawnTimeInterval = 0
            addShuriken()
        }
    }
    
    override func update(_ currentTime: CFTimeInterval) {
        var timeSinceLast = currentTime - lastUpdateTimeInterval
        lastUpdateTimeInterval = currentTime
        if timeSinceLast > 1.0 {
            timeSinceLast = 1.0 / 60.0
            lastUpdateTimeInterval = currentTime
        }
        
        updateWithTimeSinceLastUpdate(timeSinceLast: timeSinceLast)
    }
    
    func intersectionCheckAction(for effectorNode: SKNode) -> SKAction {
        let checkIntersection = SKAction.run {
            
            for object: AnyObject in self.children {
                // check for intersection against any sprites named "shuriken"
                if let node = object as? SKSpriteNode {
                    if node.name == "shuriken" {
                        // convert coordinates into common system based on root node
                        let effectorInNode = self.convert(effectorNode.position, from:effectorNode.parent!)
                        var shurikenFrame = node.frame
                        shurikenFrame.origin = self.convert(shurikenFrame.origin, from: node.parent!)
                        
                        if shurikenFrame.contains(effectorInNode) {
                            // play a hit sound
                            self.run(SKAction.playSoundFileNamed("hit.mp3", waitForCompletion: false))
                            
                            // show a spark effect
                            let spark = SKSpriteNode(imageNamed: "spark")
                            spark.position = node.position
                            spark.zPosition = 60
                            self.addChild(spark)
                            let fadeAndScaleAction = SKAction.group([SKAction.fadeOut(withDuration: 0.2), SKAction.scale(to: 0.1, duration: 0.2)])
                            let cleanUpAction = SKAction.removeFromParent()
                            spark.run(SKAction.sequence([fadeAndScaleAction, cleanUpAction]))
                            
                            // remove the shuriken
                            node.removeFromParent()
                        }
                        else {
                            // play a miss sound
                            self.run(SKAction.playSoundFileNamed("miss.mp3", waitForCompletion: false))
                        }
                    }
                }
            }
        }
        
        return checkIntersection
    }
}
