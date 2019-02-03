//
//  ViewController.swift
//  Example
//
//  Created by Lasha Efremidze on 3/8/17.
//  Copyright © 2017 efremidze. All rights reserved.
//

import SpriteKit
import Magnetic

struct Composer: Codable, Hashable {
    let shortName: String
    let next: [Composer]?
    
    var hashValue: Int {
        return shortName.hashValue
    }
}

class ViewController: UIViewController {
    var data: [Composer]?
    var onScreenData = Set<Composer>()
    var selectedData = Set<Composer>()
    
    @IBOutlet weak var magneticView: MagneticView! {
        didSet {
            magnetic.magneticDelegate = self
            #if DEBUG
                magneticView.showsFPS = true
                magneticView.showsDrawCount = true
                magneticView.showsQuadCount = true
            #endif
        }
    }
    
    var magnetic: Magnetic {
        return magneticView.magnetic
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        var nodes = [Node]()
        
        for composer in data! {
            let node = self.node(from: composer)
            nodes.append(node)
//            magnetic.addChild(node)
            onScreenData.insert(composer)
        }
        magnetic.addChildren(nodes)
        
//        let node = self.node(from: data![0])
//        nodes.append(node)
//        magnetic.addChild(node)
//        onScreenData.insert(data![0])
    }
    
    private func loadData() {
        let jsonUrl = Bundle.main.url(forResource: "composers", withExtension: "json")!
        let json = try! Data(contentsOf: jsonUrl)
        let decoder = JSONDecoder()
        let data = try! decoder.decode([Composer].self, from: json)
        print(data)
        self.data = data
    }
    
    @IBAction func add(_ sender: UIControl?) {
        let name = UIImage.names.randomItem()
        let color = UIColor.lightGray//.colors.randomItem()
        let node = ImageNode(text: name.capitalized, image: UIImage(named: name), color: color, radius: 130/2)
        magnetic.addChild(node)
        
        // Image Node: image displayed by default
        // let node = ImageNode(text: name.capitalized, image: UIImage(named: name), color: color, radius: 40)
        // magnetic.addChild(node)
    }
    
    func add(nextToNode: Node) {
        let name = UIImage.names.randomItem()
        let color = UIColor.lightGray//colors.randomItem()
        let node = ImageNode(text: name.capitalized, image: UIImage(named: name), color: color, radius: 130/2)
        node.name = "test"
//        magnetic.addChild(node, nextToNode: nextToNode)
    }
    
    func node(from data: Composer) -> Node {
        let name = data.shortName
        let color = UIColor.lightGray
        let node = ImageNode(text: name, image: nil, color: color, radius: 130/2)
        node.name = name
        return node
    }
    
    
    @IBAction func reset(_ sender: UIControl?) {
        let speed = magnetic.physicsWorld.speed
        magnetic.physicsWorld.speed = 0
        let sortedNodes = magnetic.children.compactMap { $0 as? Node }.sorted { node, nextNode in
            let distance = node.position.distance(from: magnetic.magneticField.position)
            let nextDistance = nextNode.position.distance(from: magnetic.magneticField.position)
            return distance < nextDistance && node.isSelected
        }
        var actions = [SKAction]()
        for (index, node) in sortedNodes.enumerated() {
            node.physicsBody = nil
            let action = SKAction.run { [unowned magnetic, unowned node] in
                if node.isSelected {
                    let point = CGPoint(x: magnetic.size.width / 2, y: magnetic.size.height + 40)
                    let movingXAction = SKAction.moveTo(x: point.x, duration: 0.2)
                    let movingYAction = SKAction.moveTo(y: point.y, duration: 0.4)
                    let resize = SKAction.scale(to: 0.3, duration: 0.4)
                    let throwAction = SKAction.group([movingXAction, movingYAction, resize])
                    node.run(throwAction) { [unowned node] in
                        node.removeFromParent()
                    }
                } else {
                    node.removeFromParent()
                }
            }
            actions.append(action)
            let delay = SKAction.wait(forDuration: TimeInterval(index) * 0.002)
            actions.append(delay)
        }
        magnetic.run(.sequence(actions)) { [unowned magnetic] in
            magnetic.physicsWorld.speed = speed
        }
    }
    
}

// MARK: - MagneticDelegate
extension ViewController: MagneticDelegate {
    
    func data(from node: Node) -> Composer? {
        guard let shortName = node.name else { return nil }
        return onScreenData.first(where: {$0.shortName == shortName})
    }
    
    func magnetic(_ magnetic: Magnetic, didSelect node: Node) {
        print("didSelect -> \(node)")
        guard let data = self.data(from: node) else { return }
        selectedData.insert(data)

        guard let next = data.next else { return }
        var newData = [Composer]()
        for candidate in next {
            if onScreenData.contains(candidate) == false {
                newData.append(candidate)
                onScreenData.insert(candidate)
            }
        }
        
        var nodes = [Node]()
        for data in newData {
            let node = self.node(from: data)
            nodes.append(node)
        }
        magnetic.addChildren(nodes, from: node)
    }
    
    func magnetic(_ magnetic: Magnetic, didDeselect node: Node) {
        print("didDeselect -> \(node)")
        
        guard let data = self.data(from: node) else { return }
        selectedData.remove(data)

        // find all that needs remove
        guard let toRemove = data.next else { return }
        var removeData = [Composer]()
        var test = onScreenData.subtracting(selectedData)
        for candidate in toRemove {
            if test.contains(candidate) {
                removeData.append(candidate)
                test.remove(candidate)
                onScreenData.remove(candidate)
            }
        }
        
        for data in removeData {
            let node = magnetic.childNode(withName: data.shortName)
            node?.removeFromParent()
        }
    }
}

// MARK: - ImageNode
class ImageNode: Node {
//    override var image: UIImage? {
//        didSet {
//            sprite.texture = image.map { SKTexture(image: $0) }
//        }
//    }
    
    override func selectedAnimation() {
        run(.scale(to: 1.1, duration: 0.2))
        color = .purple
//        if let texture = texture {
//            sprite.run(.setTexture(texture))
//        }
    }
    
    override func deselectedAnimation() {
        run(.scale(to: 1, duration: 0.2))
        color = .lightGray
    }
}
