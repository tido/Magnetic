//
//  MagneticView.swift
//  Magnetic
//
//  Created by Lasha Efremidze on 3/28/17.
//  Copyright © 2017 efremidze. All rights reserved.
//

import SpriteKit

open class MagneticView: SKView {
    
    @objc
    public private(set) var magnetic: Magnetic!
    
    public convenience init(magnetic: Magnetic) {
        self.init(frame: .zero, magnetic: magnetic)
        
    }
    public convenience init(frame: CGRect, magnetic: Magnetic) {
        self.init(frame: frame)
        self.magnetic = magnetic
        presentScene(scene)
    }
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        
        commonInit()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        commonInit()
    }
    
    func commonInit() {
        let scene = Magnetic(size: bounds.size)
        self.magnetic = scene
        presentScene(scene)
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        
        magnetic.size = bounds.size
    }
    
}
