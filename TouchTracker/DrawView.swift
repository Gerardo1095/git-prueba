//
//  DrawView.swift
//  TouchTracker
//
//  Created by Gerardo Mendoza Avas on 29/10/19.
//  Copyright © 2019 Gerardo Mendoza. All rights reserved.
//

import UIKit

class DrawView: UIView, UIGestureRecognizerDelegate {
    var currentLine = [NSValue: Line]()
    var finishedLines = [Line]()
    var selectedLineIndex: Int? {didSet{
        if selectedLineIndex == nil {
            let menu = UIMenuController.shared
            menu.setMenuVisible(false, animated: true)
            
        }
        }}
    
    var moveRecognizer: UIPanGestureRecognizer!
    
    @IBInspectable var finishedLineColor: UIColor = UIColor.black { didSet{
        
            setNeedsDisplay()
        }
        
        
    }
    @IBInspectable var currentLineColor: UIColor = UIColor.red { didSet{
        
        setNeedsDisplay()
        }
        
        
    }

    @IBInspectable var lineThickness: CGFloat = 10 { didSet{
        
        setNeedsDisplay()
        }
        
        
    }

    

    func stroke(_ line: Line){
        let path = UIBezierPath()
        path.lineWidth = lineThickness
        path.lineCapStyle = .round
        path.move(to: line.begin)
        path.addLine(to: line.end)
        path.stroke()
    }
    
    override func draw(_ rect: CGRect) {
        finishedLineColor.setStroke()
        for line in finishedLines {
            stroke(line)
        }
        
       //dibujar lines actuales en rojo
          currentLineColor.setStroke()
        for (_, line) in currentLine {
            
            stroke(line)
        }
        if let index = selectedLineIndex {
            UIColor.green.setStroke()
            let selectedLine = finishedLines[index]
            stroke(selectedLine)
            
        }
        
  }
    func indexOfLine(at point: CGPoint) -> Int? {
        // buscar una linea cerca del punto
        for (index, line) in finishedLines.enumerated() {
            let begin = line.begin
            let end = line.end
            
            //checar puntos en las lineas
            for t in stride(from: CGFloat(0), to: 1.0, by: 0.05){
                let x = begin.x + ((end.x - begin.x)*t)
                let y = begin.y + ((end.y - begin.y)*t)
                
           //Si el punto girado está dentro de 20 puntos, regresemos esta línea
                if hypot(x - point.x, y - point.y) < 20.0 {
                    
                    return index
                }
                
            }
            
        }
        // Si nada está lo suficientemente cerca del punto girado, entonces no seleccionamos una línea
        return nil
    }
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        //Declaración de registro para ver el orden de los eventos
        print(#function)
        for touch in touches {
            let location = touch.location(in: self)
            let newLine = Line(begin: location, end: location)
            let key = NSValue(nonretainedObject: touch)
            currentLine[key] = newLine
        }
        setNeedsDisplay()
    }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
       //orden de los eventos
        print(#function)
        for touch in touches {
            
        let key = NSValue(nonretainedObject: touch)
        currentLine[key]?.end = touch.location(in: self)
        }
        
        setNeedsDisplay()
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
      
        for touch in touches {
            
            let key = NSValue(nonretainedObject: touch)
            if var line = currentLine[key] {
                
                line.end = touch.location(in: self)
                
                
                finishedLines.append(line)
                currentLine.removeValue(forKey: key)
            }
            
        }
        setNeedsDisplay()
        
    }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        print(#function)
        currentLine.removeAll()
        setNeedsDisplay()
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        let doubleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(DrawView.doubleTap(_:)))
        doubleTapRecognizer.numberOfTapsRequired = 2
        doubleTapRecognizer.delaysTouchesBegan = true
        addGestureRecognizer(doubleTapRecognizer)
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(DrawView.tap(_:)))
        tapRecognizer.delaysTouchesBegan = true
        tapRecognizer.require(toFail: doubleTapRecognizer)
        addGestureRecognizer(tapRecognizer)
        
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(DrawView.longPress(_:)))
        addGestureRecognizer(longPressRecognizer)
        
        moveRecognizer = UIPanGestureRecognizer(target: self, action: #selector(DrawView.moveLine(_:)))
        moveRecognizer.delegate = self
        moveRecognizer.cancelsTouchesInView = false
        addGestureRecognizer(moveRecognizer)
        
    }
    @objc func tap(_ gestureRecognizer: UIGestureRecognizer){
        print("recognized a tap")
        let point = gestureRecognizer.location(in: self)
        selectedLineIndex = indexOfLine(at: point)
        
        //usando menu controller
        let menu = UIMenuController.shared
        
        if selectedLineIndex != nil {
            //Haga que DrawView sea el objetivo de los mensajes de acción de items de menú
            becomeFirstResponder()
            //Crear un nuevo "Delete" UIMenuItem
            let deleteItem = UIMenuItem(title: "Delete", action: #selector(DrawView.deleteLine(_:)))
            menu.menuItems = [deleteItem]
            
            let targetRect = CGRect(x: point.x, y: point.y, width: 2, height: 2)
            menu.setTargetRect(targetRect, in: self)
            menu.setMenuVisible(true, animated: true)
        }else {
            //ocultar el menu si no hay linea seleccionada
            menu.setMenuVisible(false, animated: false)
            
        }
        
        
        setNeedsDisplay()
    }
    
    
    @objc func doubleTap(_ gestureRecognizer: UIGestureRecognizer) {
        print("Recognized a double tap")
        selectedLineIndex = nil
        currentLine.removeAll()
        finishedLines.removeAll()
        setNeedsDisplay()
    }
    override var canBecomeFirstResponder: Bool {
        return true
    }
    @objc func deleteLine(_ sender: UIMenuController){
        //eliminar la linea seleccionada de las lineas que ya estan terminadas
        if let index = selectedLineIndex {
            finishedLines.remove(at: index)
            selectedLineIndex = nil
            
            //redibuja todo
            setNeedsDisplay()
        }
        
        
    }
    @objc func longPress(_ gestureRecognizer: UIGestureRecognizer){
        print("Recognizer a long press")
        if gestureRecognizer.state == .began {
            let point = gestureRecognizer.location(in: self)
            selectedLineIndex = indexOfLine(at: point)
            
            if selectedLineIndex != nil {
                
                currentLine.removeAll()
            }
            
        }else {
            
            if gestureRecognizer.state == .ended {
                selectedLineIndex = nil
            }
        }
        setNeedsDisplay()
    }
    @objc func moveLine(_ gestureRecognizer: UIPanGestureRecognizer){
        print("Recognized a pan")
        //si una linea se selecciona
        if let index = selectedLineIndex {
            
            //cuando el reconocedor pan cambia su posicion.
            if gestureRecognizer.state == .changed{
                //hasta donde se mueve pan?
                let translation = gestureRecognizer.translation(in: self)
                finishedLines[index].begin.x += translation.x
                finishedLines[index].begin.y += translation.y
                finishedLines[index].end.x += translation.x
                finishedLines[index].end.y += translation.y
                
                gestureRecognizer.setTranslation(CGPoint.zero, in: self)
                // Redraw the screen
                setNeedsDisplay()
            }
        } else {
            // If no line is selected, do not do anything
            return }
        
    }
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
        
    }
        }
        




