//
//  GameScene.swift
//  FlappyBird
//
//  Created by 理化学Mac on 2018/07/28.
//  Copyright © 2018年 yuusukesaito. All rights reserved.
//

import SpriteKit
import AVFoundation

class GameScene: SKScene, SKPhysicsContactDelegate {
    var scrollNode:SKNode!
    var wallNode:SKNode!
    var bird:SKSpriteNode!
    var itemNode:SKNode!
    let birdCategory: UInt32 = 1 << 0
    let groundCategory: UInt32 = 1 << 1
    let wallCategory: UInt32 = 1 << 2
    let scoreCategory: UInt32 = 1 << 3
    let itemCategory: UInt32 = 1 << 4
    var score = 0
    var scoreLabelNode:SKLabelNode!
    var bestScorLabelNode:SKLabelNode!
    var itemScore = 0
    var itemScoreLabelNode:SKLabelNode!
    let userDefaults:UserDefaults = UserDefaults.standard
    
    override func didMove(to view: SKView) {
        physicsWorld.gravity = CGVector(dx: 0.0, dy: -4.0)
        physicsWorld.contactDelegate = self
        backgroundColor = UIColor(red: 0.15, green: 0.75, blue: 0.90, alpha: 1)
        scrollNode = SKNode()
        addChild(scrollNode)
        wallNode = SKNode()
        scrollNode.addChild(wallNode)
        setupGround()
        setupCloud()
        setupWall()
        setupBird()
        setupScoreLabel()
    }
    
    func setupGround() {
        let groundTexture = SKTexture(imageNamed: "ground")
        groundTexture.filteringMode = .nearest
        let needNumber = Int(self.frame.size.width / groundTexture.size().width) + 2
        let moveGround = SKAction.moveBy(x: -groundTexture.size().width, y: 0, duration: 5.0)
        let resetGround = SKAction.moveBy(x: groundTexture.size().width, y: 0, duration: 0.0)
        let repeatScrollGround = SKAction.repeatForever(SKAction.sequence([moveGround,resetGround]))
        for i in 0..<needNumber {
            let sprit = SKSpriteNode(texture: groundTexture)
            sprit.position = CGPoint(
                x: groundTexture.size().width * (CGFloat(i) + 0.5),
                y: groundTexture.size().height * 0.5
            )
            sprit.run(repeatScrollGround)
            sprit.physicsBody = SKPhysicsBody(rectangleOf: groundTexture.size())
            sprit.physicsBody?.categoryBitMask = groundCategory
            sprit.physicsBody?.isDynamic = false
            scrollNode.addChild(sprit)
        }
    }
    
    func setupCloud() {
        let cloudTexture = SKTexture(imageNamed: "cloud")
        cloudTexture.filteringMode = .nearest
        let needCloudNumber = Int(self.frame.size.width / cloudTexture.size().width) + 2
        let moveCloud = SKAction.moveBy(x: -cloudTexture.size().width, y: 0, duration: 20.0)
        let resetCloud = SKAction.moveBy(x: cloudTexture.size().width, y: 0, duration: 0.0)
        let repeatScrollCloud = SKAction.repeatForever(SKAction.sequence([moveCloud,resetCloud]))
        for i in 0..<needCloudNumber {
            let sprit = SKSpriteNode(texture: cloudTexture)
            sprit.zPosition = -100
            sprit.position = CGPoint(
                x: cloudTexture.size().width * (CGFloat(i) + 0.5),
                y: self.size.height - cloudTexture.size().height * 0.5
            )
            sprit.run(repeatScrollCloud)
            scrollNode.addChild(sprit)
        }
    }
    
    func setupWall() {
        let wallTexture = SKTexture(imageNamed: "wall")
        wallTexture.filteringMode = .linear
        let itemTexture = SKTexture(imageNamed: "onigiri_yukari_a")
        itemTexture.filteringMode = .linear
        let movingDistance = CGFloat(self.frame.size.width + wallTexture.size().width + itemTexture.size().width)
        let moveWall = SKAction.moveBy(x: -movingDistance, y: 0, duration: 4.0)
        let removeWall = SKAction.removeFromParent()
        let wallAnimation = SKAction.sequence([moveWall, removeWall])
        let createWallAnimation = SKAction.run({
            let wall = SKNode()
            wall.position = CGPoint(x: self.frame.size.width + wallTexture.size().width / 2, y: 0.0)
            wall.zPosition = -50
            let center_y = self.frame.size.height / 2
            let random_y_range = self.frame.size.height / 4
            let under_wall_lowest_y = UInt32( center_y - wallTexture.size().height / 2 - random_y_range / 2)
            let random_y = arc4random_uniform( UInt32(random_y_range) )
            let under_wall_y = CGFloat( under_wall_lowest_y + random_y)
            let slit_length = self.frame.size.height / 6
            let under = SKSpriteNode(texture: wallTexture)
            under.position = CGPoint(x: 0.0, y: under_wall_y)
            under.physicsBody = SKPhysicsBody(rectangleOf: wallTexture.size())
            under.physicsBody?.categoryBitMask = self.wallCategory
            under.physicsBody?.isDynamic = false
            wall.addChild(under)
            let upper = SKSpriteNode(texture: wallTexture)
            upper.position = CGPoint(x: 0.0, y: under_wall_y + wallTexture.size().height + slit_length)
            upper.physicsBody = SKPhysicsBody(rectangleOf: wallTexture.size())
            upper.physicsBody?.categoryBitMask = self.wallCategory
            upper.physicsBody?.isDynamic = false
            wall.addChild(upper)
            //itemの作成
            let item = SKSpriteNode(texture: itemTexture)
            item.position = CGPoint(x: wallTexture.size().width * -3 , y: self.frame.size.height / 2.0)
            item.physicsBody = SKPhysicsBody(rectangleOf: itemTexture.size())
            item.physicsBody?.isDynamic = false
            item.physicsBody?.categoryBitMask = self.itemCategory
            item.physicsBody?.contactTestBitMask = self.birdCategory
            wall.addChild(item)
            let scoreNode = SKNode()
            scoreNode.position = CGPoint(x: upper.size.width + self.bird.size.width / 2, y: self.frame.height / 2.0)
            scoreNode.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: upper.size.width, height: self.frame.size.height))
            scoreNode.physicsBody?.isDynamic = false
            scoreNode.physicsBody?.categoryBitMask = self.scoreCategory
            scoreNode.physicsBody?.contactTestBitMask = self.birdCategory
            wall.addChild(scoreNode)
            wall.run(wallAnimation)
            self.wallNode.addChild(wall)
        })
        let waitAnimation = SKAction.wait(forDuration: 2)
        let repeatForeverAnimation = SKAction.repeatForever(SKAction.sequence([createWallAnimation, waitAnimation]))
        wallNode.run(repeatForeverAnimation)
    }
    
    func setupBird() {
        let birdTextureA = SKTexture(imageNamed: "bird_a")
        birdTextureA.filteringMode = .linear
        let birdTextureB = SKTexture(imageNamed: "bird_b")
        birdTextureB.filteringMode = .linear
        let texturesAnimation = SKAction.animate(with: [birdTextureA, birdTextureB], timePerFrame: 0.2)
        let flap = SKAction.repeatForever(texturesAnimation)
        bird = SKSpriteNode(texture: birdTextureA)
        bird.position = CGPoint(x: self.frame.size.width * 0.2, y: self.frame.size.height * 0.7)
        bird.physicsBody = SKPhysicsBody(circleOfRadius: bird.size.height / 2.0)
        bird.physicsBody?.allowsRotation = false
        bird.physicsBody?.categoryBitMask = birdCategory
        bird.physicsBody?.collisionBitMask = groundCategory | wallCategory
        bird.physicsBody?.contactTestBitMask = groundCategory | wallCategory
        bird.run(flap)
        addChild(bird)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if scrollNode.speed > 0 {
            bird.physicsBody?.velocity = CGVector.zero
            bird.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 15))
        } else if bird.speed == 0 {
            restart()
        }
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        if scrollNode.speed <= 0 {
            return
        }
        if (contact.bodyA.categoryBitMask & scoreCategory) == scoreCategory || (contact.bodyB.categoryBitMask & scoreCategory) == scoreCategory {
            print("ScoreUp")
            score += 1
            scoreLabelNode.text = "Score:\(score)"
            var bestScore = userDefaults.integer(forKey: "BEST")
            if score > bestScore {
                bestScore = score
                bestScorLabelNode.text = "Best Score:\(bestScore)"
                userDefaults.set(bestScore, forKey: "BEST")
                userDefaults.synchronize()
            }
        }
            ///アイテムスコアーの加算
        else if (contact.bodyA.categoryBitMask & itemCategory) == itemCategory || (contact.bodyB.categoryBitMask & itemCategory) == itemCategory {
            print("ItemScoreUp")
            let music = SKAction.playSoundFileNamed("decision22.mp3", waitForCompletion: true)
            let repeatMusic = SKAction.repeat(music, count: 1)
            self.run(repeatMusic)
            itemScore += 1
            itemScoreLabelNode.text = "Item Score:\(itemScore)"
            if (contact.bodyA.categoryBitMask == itemCategory) {
                contact.bodyA.node?.removeFromParent()
            } else {
                contact.bodyB.node?.removeFromParent()
            }
        }else {
            print("GameOver")
            scrollNode.speed = 0
            bird.physicsBody?.collisionBitMask = groundCategory
            let roll = SKAction.rotate(byAngle: CGFloat(Double.pi) * CGFloat(bird.position.y) * 0.01, duration: 1)
            bird.run(roll, completion:{
                self.bird.speed = 0
            })
        }
    }
    
    func restart() {
        score = 0
        scoreLabelNode.text = String("Score:\(score)")
        itemScore=0
        itemScoreLabelNode.text = String("Item Score:\(itemScore)")
        bird.position = CGPoint(x: self.frame.size.width * 0.2, y: self.frame.size.height * 0.7)
        bird.physicsBody?.velocity = CGVector.zero
        bird.physicsBody?.collisionBitMask = groundCategory | wallCategory
        bird.zRotation = 0.0
        wallNode.removeAllChildren()
        bird.speed = 1
        scrollNode.speed = 1
    }
    
    func setupScoreLabel() {
        score = 0
        scoreLabelNode = SKLabelNode()
        scoreLabelNode.fontColor = UIColor.black
        scoreLabelNode.position = CGPoint(x: 10, y: self.size.height - 60)
        scoreLabelNode.zPosition = 100
        scoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        scoreLabelNode.text = "Score:\(score)"
        self.addChild(scoreLabelNode)
        bestScorLabelNode = SKLabelNode()
        bestScorLabelNode.fontColor = UIColor.black
        bestScorLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 90)
        bestScorLabelNode.zPosition = 100
        bestScorLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        let bestScore = userDefaults.integer(forKey: "BEST")
        bestScorLabelNode.text = "Best Score:\(bestScore)"
        self.addChild(bestScorLabelNode)
        //ItemScoreラベルの表示
        itemScore = 0
        itemScoreLabelNode = SKLabelNode()
        itemScoreLabelNode.fontColor = UIColor.black
        itemScoreLabelNode.position = CGPoint(x: 10, y: self.size.height - 120)
        itemScoreLabelNode.zPosition = 100
        itemScoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        itemScoreLabelNode.text = "Item Score:\(itemScore)"
        self.addChild(itemScoreLabelNode)
    }
}


