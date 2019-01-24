//
//  Magnetic.swift
//  Magnetic
//
//  Created by Lasha Efremidze on 3/8/17.
//  Copyright © 2017 efremidze. All rights reserved.
//

import SpriteKit

@objc public protocol MagneticDelegate: class {
    func magnetic(_ magnetic: Magnetic, didSelect node: Node)
    func magnetic(_ magnetic: Magnetic, didDeselect node: Node)
}

@objcMembers open class Magnetic: SKScene {
    
    /**
     The field node that accelerates the nodes.
     */
    open lazy var magneticField: SKFieldNode = { [unowned self] in
        let field = SKFieldNode.radialGravityField()
        self.addChild(field)
        return field
    }()
    
    /**
     Controls whether you can select multiple nodes.
     */
    open var allowsMultipleSelection: Bool = true
    
    open var isDragging: Bool = false
    
    /**
     The selected children.
     */
    open var selectedChildren: [Node] {
        return children.compactMap { $0 as? Node }.filter { $0.isSelected }
    }
    
    /**
     The object that acts as the delegate of the scene.
     
     The delegate must adopt the MagneticDelegate protocol. The delegate is not retained.
     */
    open weak var magneticDelegate: MagneticDelegate?
    
    override open var size: CGSize {
        didSet {
            configure()
        }
    }
    
    override public init(size: CGSize) {
        super.init(size: size)
        
        commonInit()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        commonInit()
    }
    
    func commonInit() {
        backgroundColor = .white
        scaleMode = .aspectFill
        configure()
    }
    
    func configure() {
        let strength = Float(max(size.width, size.height))
        let radius = strength.squareRoot() * 100
        
        physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        physicsBody = SKPhysicsBody(edgeLoopFrom: { () -> CGRect in
            var frame = self.frame
            frame.size.width = CGFloat(radius)
            frame.origin.x -= frame.size.width / 2
            return frame
        }())
        
        magneticField.region = SKRegion(radius: radius)
        magneticField.minimumRadius = radius
        magneticField.strength = strength
        magneticField.position = CGPoint(x: size.width / 2, y: size.height / 2)
    }
    
    override open func addChild(_ node: SKNode) {
        var x = -node.frame.width // left
        if children.count % 2 == 0 {
            x = frame.width + node.frame.width // right
        }
        let y = CGFloat.random(node.frame.height, frame.height - node.frame.height)
        node.position = CGPoint(x: x, y: y)
        super.addChild(node)
    }
    
    open func addChildren(_ nodes: [SKNode], from node: Node, delay: Double = 0.2, duration: Double = 0.4) {
        enum Quadrant: Int {
            case left = 0, top, right, bottom
            
            func position(from node: Node) -> CGPoint {
                switch self {
                case .left:     return CGPoint(x: node.frame.origin.x, y: node.frame.origin.y + node.frame.size.height / 2)
                case .top:      return CGPoint(x: node.frame.origin.x + node.frame.size.width / 2, y: node.frame.origin.y)
                case .right:    return CGPoint(x: node.frame.origin.x + node.frame.size.width, y: node.frame.origin.y + node.frame.size.height / 2)
                case .bottom:   return CGPoint(x: node.frame.origin.x + node.frame.size.width / 2, y: node.frame.origin.y + node.frame.size.height)
                }
            }
            
            var next: Quadrant {
                switch self {
                case .left:     return .top
                case .top:      return .right
                case .right:    return .bottom
                case .bottom:   return .top
                }
            }
        }
        
        var quadrant = Quadrant.left
        for (index, newNode) in nodes.enumerated() {
            newNode.position = quadrant.position(from: node)
            quadrant = quadrant.next
            super.addChild(newNode)

            let start = SKAction.scale(to: 0, duration: 0)
            let wait = SKAction.wait(forDuration: Double(index) * delay)
            let scale = SKAction.scale(to: 1, duration: duration)
            scale.timingMode = .easeOut
            newNode.run(.sequence([start, wait, scale]))
        }
    }
    
    open func removeChildren(_ nodes: [SKNode], delay: Double = 0.2, duration: Double = 0.4) {
        for (index, node) in nodes.enumerated() {
            let wait = SKAction.wait(forDuration: Double(index) * delay)
            let scale = SKAction.scale(to: 0, duration: duration)
//            let fade = SKAction.scale(to: 0, duration: duration)
            scale.timingMode = .easeIn

            node.run(.sequence([wait, scale])) {
                node.removeFromParent()
            }
        }
    }
}

extension Magnetic {
    
    override open func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let previous = touch.previousLocation(in: self)
        guard location.distance(from: previous) != 0 else { return }
        
        isDragging = true
        
        moveNodes(location: location, previous: previous)
    }
    
    override open func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        defer { isDragging = false }
        guard !isDragging, let node = node(at: location) else { return }
        
        if node.isSelected {
            node.isSelected = false
            magneticDelegate?.magnetic(self, didDeselect: node)
        } else {
            if !allowsMultipleSelection, let selectedNode = selectedChildren.first {
                selectedNode.isSelected = false
                magneticDelegate?.magnetic(self, didDeselect: selectedNode)
            }
            node.isSelected = true
            magneticDelegate?.magnetic(self, didSelect: node)
        }
    }
    
    override open func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        isDragging = false
    }
    
}

extension Magnetic {
    
    open func moveNodes(location: CGPoint, previous: CGPoint) {
        let x = location.x - previous.x
        let y = location.y - previous.y
        
        for node in children {
            let distance = node.position.distance(from: location)
            let acceleration: CGFloat = 3 * pow(distance, 1/2)
            let direction = CGVector(dx: x * acceleration, dy: y * acceleration)
            node.physicsBody?.applyForce(direction)
        }
    }
    
    open func node(at point: CGPoint) -> Node? {
        return nodes(at: point).compactMap { $0 as? Node }.filter { $0.path!.contains(convert(point, to: $0)) }.first
    }
    
}
