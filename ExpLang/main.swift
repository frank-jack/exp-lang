//
//  main.swift
//  ExpLang
//
//  Created by Jack Frank on 3/18/23.
//

import Foundation

extension String {
    var isNumber: Bool {
        let digitsCharacters = CharacterSet(charactersIn: ".0123456789-")
        return CharacterSet(charactersIn: self).isSubset(of: digitsCharacters)
    }
}

extension StringProtocol {
    subscript(offset: Int) -> Character {
        self[index(startIndex, offsetBy: offset)]
    }
    func customReplace() -> String {
        var output = ""
        var inQ = false
        if 0 <= self.count-1 {
            for i in 0...self.count-1 {
                if self[i] == "\"" {
                    inQ.toggle()
                }
                if self[i] != " " || inQ {
                    output+=String(self[i])
                }
            }
        }
        return output
    }
}

enum TypeValue {
    case String
    case Float
    case Boolean
    case Array
    case Function
    case Void
    case TypeError
}

struct Function {
    var params: [(name: String, type: TypeValue)]
    var code: String
    var returnType: TypeValue
}

func evaluate(code: String, space: [(name: String, value: Any, type: TypeValue, global: Bool)]) -> (value: String, space: [(name: String, value: Any, type: TypeValue, global: Bool)]) {
    if code.replacingOccurrences(of: " ", with: "").count == 0 {
        return ("", space)
    }
    if getVarNames(space: space).contains(code) {
        return (evaluate(code: getValue(variable: code, space: space), space: space).value, space)
    }
    if getFunctionNames(space: space).contains(where: code.customReplace().hasPrefix) && code.contains("(") && code.contains(")") && getFunction(funcName: code.customReplace().components(separatedBy: "(")[0], space: space).returnType != TypeValue.Void {
        var localSpace = [(name: String, value: Any, type: TypeValue, global: Bool)]()
        let funcName = code.customReplace().components(separatedBy: "(")[0]
        let funcParam = code.customReplace().dropLast(1).components(separatedBy: "(")[1].components(separatedBy: ",")
        if funcParam[0].count > 0 {
            for i in funcParam {
                if getType(variable: evaluate(code: i.components(separatedBy: ":")[1], space: space).value) == TypeValue.String {
                    localSpace.append((name: String(i.components(separatedBy: ":")[0]), value: evaluate(code: i.components(separatedBy: ":")[1], space: space).value, type: TypeValue.String, global: false))
                } else if getType(variable: evaluate(code: i.components(separatedBy: ":")[1], space: space).value) == TypeValue.Float {
                    localSpace.append((name: i.components(separatedBy: ":")[0], value: Float(evaluate(code: i.components(separatedBy: ":")[1], space: space).value)!, type: TypeValue.Float, global: false))
                } else if getType(variable: evaluate(code: i.components(separatedBy: ":")[1], space: space).value) == TypeValue.Boolean {
                    localSpace.append((name: i.components(separatedBy: ":")[0], value: evaluate(code: i.components(separatedBy: ":")[1], space: space).value, type: TypeValue.Boolean, global: false))
                } else if getType(variable: evaluate(code: i.components(separatedBy: ":")[1], space: space).value) == TypeValue.Array {
                    localSpace.append((name: i.components(separatedBy: ":")[0], value: evaluate(code: i.components(separatedBy: ":")[1], space: space).value, type: TypeValue.Array, global: false))
                }
            }
        }
        let functionValue = getFunction(funcName: funcName, space: space)
        var paramsValid = true
        if functionValue.params.count > 1 {
            for i in 0...functionValue.params.count-1 {
                if functionValue.params[i].name != localSpace[i].name || functionValue.params[i].type != localSpace[i].type {
                    paramsValid = false
                }
            }
        }
        if paramsValid {
            for i in space {
                if i.global {
                    localSpace.append(i)
                }
            }
            var newSpace = run(code: functionValue.code, space: localSpace, global: false).space
            let tempCount = newSpace.count-1
            for i in 0...tempCount {
                if !newSpace[tempCount-i].global {
                    newSpace.remove(at: tempCount-i)
                }
            }
            if getType(variable: run(code: functionValue.code, space: localSpace, global: false).returnValue) == functionValue.returnType {
                return (run(code: functionValue.code, space: localSpace, global: false).returnValue, newSpace)
            }
        }
    }
    if code.components(separatedBy: "[").count-1 == 1 && code.components(separatedBy: "]").count-1 == 1 && getType(variable: evaluate(code: code.customReplace().components(separatedBy: "[")[0], space: space).value) == TypeValue.String {
        return ("\""+String(evaluate(code: code.customReplace().components(separatedBy: "[")[0], space: space).value[Int(code.components(separatedBy: "[")[1].dropLast(1))!+1])+"\"", space)
    }
    if code.contains("[") && code.contains("]") && getVarNames(space: space).contains(code.customReplace().components(separatedBy: "[")[0]) && getType(variable: evaluate(code: code.customReplace().components(separatedBy: "[")[0], space: space).value) == TypeValue.Array {
        var arr = evaluate(code: code.customReplace().components(separatedBy: "[")[0], space: space).value
        var finished = false
        var count = 1
        while !finished {
            var editedCode = ""
            var depth = 0
            for i in 0...arr.count-1 {
                if arr[i] == "[" {
                    depth+=1
                } else if arr[i] == "]" {
                    depth-=1
                }
                if arr[i] == "," && depth > 1 {
                    editedCode+="\0"
                } else {
                    editedCode+=String(arr[i])
                }
            }
            var arrayItems = editedCode.customReplace().dropFirst(1).dropLast(1).components(separatedBy: ",")
            for i in 0...arrayItems.count-1 {
                arrayItems[i] = arrayItems[i].replacingOccurrences(of: "\0", with: ",")
            }
            if getType(variable: evaluate(code: arrayItems[Int(code.components(separatedBy: "[")[count].dropLast(1))!], space: space).value) != TypeValue.Array || count == code.components(separatedBy: "[").count-1 {
                finished = true
                return (evaluate(code: arrayItems[Int(code.components(separatedBy: "[")[count].dropLast(1))!], space: space).value, space)
            } else {
                arr = evaluate(code: arrayItems[Int(code.components(separatedBy: "[")[count].dropLast(1))!], space: space).value
                count+=1
            }
        }
    }
    if code.components(separatedBy: "[").count-1 > 2 && code.components(separatedBy: "]").count-1 > 2 && code.customReplace()[0] == "[" && (Int(code.customReplace().components(separatedBy: "[")[code.customReplace().components(separatedBy: "[").count-1].dropLast(1)) != nil) {
        var leftBrackets = 0
        var depth = 0
        var stop = 0
        for i in 0...code.customReplace().count-1 {
            if depth == 0 {
                stop+=1
            }
            if stop < 2 {
                if code.customReplace()[i] == "[" {
                    depth+=1
                    leftBrackets+=1
                } else if code.customReplace()[i] == "]" {
                    depth-=1
                }
            }
        }
        let splitByBrackets = code.customReplace().components(separatedBy: "[")
        var arr = ""
        for i in 0...leftBrackets {
            if i == 0 {
                arr+=splitByBrackets[i]
            } else {
                arr+="["+splitByBrackets[i]
            }
        }
        arr = evaluate(code: arr, space: space).value
        var finished = false
        var count = leftBrackets+1
        while !finished {
            var editedCode = ""
            var depth = 0
            for i in 0...arr.count-1 {
                if arr[i] == "[" {
                    depth+=1
                } else if arr[i] == "]" {
                    depth-=1
                }
                if arr[i] == "," && depth > 1 {
                    editedCode+="\0"
                } else {
                    editedCode+=String(arr[i])
                }
            }
            var arrayItems = editedCode.customReplace().dropFirst(1).dropLast(1).components(separatedBy: ",")
            for i in 0...arrayItems.count-1 {
                arrayItems[i] = arrayItems[i].replacingOccurrences(of: "\0", with: ",")
            }
            if getType(variable: evaluate(code: arrayItems[Int(code.components(separatedBy: "[")[count].dropLast(1))!], space: space).value) != TypeValue.Array || count == code.components(separatedBy: "[").count-1 {
                finished = true
                return (evaluate(code: arrayItems[Int(code.components(separatedBy: "[")[count].dropLast(1))!], space: space).value, space)
            } else {
                arr = evaluate(code: arrayItems[Int(code.components(separatedBy: "[")[count].dropLast(1))!], space: space).value
                count+=1
            }
        }
    }
    if code.customReplace()[0] == "[" && code.customReplace()[code.customReplace().count-1] == "]" {
        var editedCode = ""
        var depth = 0
        for i in 0...code.count-1 {
            if code[i] == "[" {
                depth+=1
            } else if code[i] == "]" {
                depth-=1
            }
            if code[i] == "," && depth > 1 {
                editedCode+="\0"
            } else {
                editedCode+=String(code[i])
            }
        }
        var arrayItems = editedCode.customReplace().dropFirst(1).dropLast(1).components(separatedBy: ",")
        for i in 0...arrayItems.count-1 {
            arrayItems[i] = arrayItems[i].replacingOccurrences(of: "\0", with: ",")
        }
        for i in 0...arrayItems.count-1 {
            arrayItems[i] = evaluate(code: arrayItems[i], space: space).value
        }
        var output = "["
        for i in 0...arrayItems.count-1 {
            output+=arrayItems[i]
            if i != arrayItems.count-1 {
                output+=","
            }
        }
        output+="]"
        return (output, space)
    }
    if code.customReplace() == "true" || code.customReplace() == "false" {
        return (String(code.customReplace()), space)
    }
    if code.customReplace() == "!true" {
        return ("false", space)
    }
    if code.customReplace() == "!false" {
        return ("true", space)
    }
    if code.customReplace()[0] == "!" && getType(variable: evaluate(code: String(code.customReplace().dropFirst(1)), space: space).value) == TypeValue.Boolean && getVarNames(space: space).contains(String(code.customReplace().dropFirst(1))) {
        if evaluate(code: String(code.customReplace().dropFirst(1)), space: space).value == "true" {
            return ("false", space)
        } else if evaluate(code: String(code.customReplace().dropFirst(1)), space: space).value == "false" {
            return ("true", space)
        }
    }
    if code.contains("<") || code.contains(">") || code.contains("==") || code.contains("!=") || code.contains("||") || code.contains("&&") {
        var parenIds = [Int]()
        var valIds = [Int]()
        var orIds = [Int]()
        var andIds = [Int]()
        var depth = 0
        var depthChanged = false
        for i in 0...code.count-1 {
            if code[i] == "(" {
                if depth > 0 {
                    parenIds.append(i)
                }
                depth+=1
                depthChanged = true
            } else if code[i] == ")" {
                if depth > 0 && depthChanged {
                    parenIds.append(i)
                }
                depth-=1
            } else if depth > 0 {
                parenIds.append(i)
            } else if depth == 0 && code[i] == "&" && code[i+1] == "&" {
                andIds.append(i)
            } else if depth == 0 && code[i] == "|" && code[i+1] == "|" {
                orIds.append(i)
            } else if code[i] != ">" && code[i] != "<" && code[i] != "=" && !(code[i] == "!" && code[i+1] == "=") && code[i] != "|" && code[i] != "&" && depth == 0 {
                valIds.append(i)
            }
        }
        var parens = [String]()
        var parenIdsUsed = [Int]()
        for i in parenIds {
            if !parenIdsUsed.contains(i) {
                var index = i
                var paren = ""
                while parenIds.contains(index) {
                    paren+=String(code[index])
                    index+=1
                    parenIdsUsed.append(index)
                }
                parens.append(paren)
            }
        }
        var vals = [String]()
        var valIdsUsed = [Int]()
        for i in valIds {
            if !valIdsUsed.contains(i) {
                var index = i
                var val = ""
                while valIds.contains(index) {
                    val+=String(code[index])
                    index+=1
                    valIdsUsed.append(index)
                }
                vals.append(val)
            }
        }
        var expression = [String]()
        var parenCount = 0
        var valCount = 0
        for i in 0...code.count-1 {
            if parenIds.contains(i) && !parenIdsUsed.contains(i) {
                expression.append(evaluate(code: parens[parenCount], space: space).value)
                parenCount+=1
            } else if valIds.contains(i) && !valIdsUsed.contains(i) && !parenIds.contains(i) {
                expression.append(evaluate(code: vals[valCount], space: space).value)
                valCount+=1
            } else if code[i] == ">" && code[i+1] == "=" && !parenIds.contains(i) {
                expression.append(">=")
            } else if code[i] == "<" && code[i+1] == "=" && !parenIds.contains(i) {
                expression.append("<=")
            } else if code[i] == ">" && !parenIds.contains(i) {
                expression.append(">")
            } else if code[i] == "<" && !parenIds.contains(i) {
                expression.append("<")
            } else if code[i] == "=" && code[i+1] == "=" && !parenIds.contains(i) {
                expression.append("==")
            } else if code[i] == "!" && code[i+1] == "=" && !parenIds.contains(i) {
                expression.append("!=")
            } else if orIds.contains(i) {
                expression.append("||")
            } else if andIds.contains(i) {
                expression.append("&&")
            }
        }
        for i in 0...expression.count-1 {
            if expression[i] == "<" {
                if Float(expression[i-1])! < Float(expression[i+1])! {
                    expression[i] = "true"
                } else {
                    expression[i] = "false"
                }
                expression[i-1] = ""
                expression[i+1] = ""
            } else if expression[i] == ">" {
                if Float(expression[i-1])! > Float(expression[i+1])! {
                    expression[i] = "true"
                } else {
                    expression[i] = "false"
                }
                expression[i-1] = ""
                expression[i+1] = ""
            } else if expression[i] == "==" {
                if expression[i-1] == expression[i+1] {
                    expression[i] = "true"
                } else {
                    expression[i] = "false"
                }
                expression[i-1] = ""
                expression[i+1] = ""
            } else if expression[i] == "<=" {
                if Float(expression[i-1])! <= Float(expression[i+1])! {
                    expression[i] = "true"
                } else {
                    expression[i] = "false"
                }
                expression[i-1] = ""
                expression[i+1] = ""
            } else if expression[i] == ">=" {
                if Float(expression[i-1])! >= Float(expression[i+1])! {
                    expression[i] = "true"
                } else {
                    expression[i] = "false"
                }
                expression[i-1] = ""
                expression[i+1] = ""
            } else if expression[i] == "!=" {
                if expression[i-1] != expression[i+1] {
                    expression[i] = "true"
                } else {
                    expression[i] = "false"
                }
                expression[i-1] = ""
                expression[i+1] = ""
            }
        }
        expression.removeAll { $0 == "" }
        while expression.count != 1 {
            for i in 0...expression.count-1 {
                if i <= expression.count-1 && expression[i] == "||" {
                    if expression[i-1] == "true" || expression[i+1] == "true" {
                        expression[i] = "true"
                    } else {
                        expression[i] = "false"
                    }
                    expression[i-1] = ""
                    expression[i+1] = ""
                } else if i <= expression.count-1 && expression[i] == "&&" {
                    if expression[i-1] == "true" && expression[i+1] == "true" {
                        expression[i] = "true"
                    } else {
                        expression[i] = "false"
                    }
                    expression[i-1] = ""
                    expression[i+1] = ""
                }
                expression.removeAll { $0 == "" }
            }
        }
        return (expression[0], space)
    }
    if !code.contains("\"") && !code.contains("+") && !code.contains("-") && !code.contains("*") && !code.contains("/") && !code.contains("(") && !code.contains(")") && !code.isNumber && getType(variable: getValue(variable: code, space: space)) == TypeValue.Boolean {
        return (evaluate(code: getValue(variable: code.customReplace(), space: space), space: space).value, space)
    }
    if !code.contains("\"") && !code.contains("+") && !code.contains("-") && !code.contains("*") && !code.contains("/") && !code.contains("(") && !code.contains(")") && code.customReplace().isNumber {
        return (code.customReplace(), space)
    } else if !code.contains("\"") && !code.contains("-") && !code.contains("*") && !code.contains("/") && !code.contains("(") && !code.contains(")") {
        var simpleAdds: Float = 0.0
        let splitByPlus = code.components(separatedBy: "+")
        var allNumbers = true
        for i in splitByPlus {
            if evaluate(code: i.customReplace(), space: space).value.isNumber {
                simpleAdds+=Float(evaluate(code: i.customReplace(), space: space).value)!
            } else {
                allNumbers = false
            }
        }
        if allNumbers {
            return (String(simpleAdds), space)
        }
    }
    var isFloatExpression = false
    if !code.contains("\"") {
        if code.contains("-") || code.contains("*") || code.contains("/") || code.contains("(") || code.contains(")") {
            isFloatExpression = true
        } 
        if code.contains("+") {
            let splitByPlus = code.components(separatedBy: "+")
            for i in splitByPlus {
                if !i.isNumber {
                    if getType(variable: getValue(variable: i, space: space)) == TypeValue.Float {
                        isFloatExpression = true
                    }
                }
            }
        }
    }
    if code.contains("\"") || !isFloatExpression {
        var inQ = false
        var tempVarName = ""
        var trueCode = ""
        for i in code {
            if i == "\"" {
                inQ.toggle()
            }
            if i != "\"" && i != "+" && !inQ {
                if i != " " {
                    tempVarName+=String(i)
                }
            }
            if i == "\"" || i == "+" || inQ || i == code[code.count-1] {
                if tempVarName.count > 0 {
                    trueCode+=getValue(variable: tempVarName, space: space)
                    tempVarName = ""
                } else {
                    trueCode+=String(i)
                }
            }
        }
        var output = ""
        for i in trueCode {
            if i != "\"" && i != "+" {
                output = output+String(i)
            }
        }
        return ("\""+output+"\"", space)
    }
    var numbIds = [Int]()
    var parenIds = [Int]()
    var varIds = [Int]()
    var depth = 0
    var depthChanged = false
    for i in 0...code.count-1 {
        if code[i] == "(" {
            if depth > 0 {
                parenIds.append(i)
            }
            depth+=1
            depthChanged = true
        } else if code[i] == ")" {
            if depth > 0 && depthChanged {
                parenIds.append(i)
            }
            depth-=1
        } else if depth > 0 {
            parenIds.append(i)
        } else if code[i].isLetter && depth == 0 {
            varIds.append(i)
        } else if (code[i].isNumber || code[i] == ".") && depth == 0 {
            numbIds.append(i)
        }
    }
    var numbs = [String]()
    var numbIdsUsed = [Int]()
    for i in numbIds {
        if !numbIdsUsed.contains(i) {
            var index = i
            var numb = ""
            while numbIds.contains(index) {
                numb+=String(code[index])
                index+=1
                numbIdsUsed.append(index)
            }
            numbs.append(numb)
        }
    }
    var parens = [String]()
    var parenIdsUsed = [Int]()
    for i in parenIds {
        if !parenIdsUsed.contains(i) {
            var index = i
            var paren = ""
            while parenIds.contains(index) {
                paren+=String(code[index])
                index+=1
                parenIdsUsed.append(index)
            }
            parens.append(paren)
        }
    }
    var vars = [String]()
    var varIdsUsed = [Int]()
    for i in varIds {
        var index = i
        while varIds.contains(index) || (index <= code.count-1 && code[index] != "+" && code[index] != "-" && code[index] != "*" && code[index] != "/" && code[index] != "(" && code[index] != ")") {
            if !varIds.contains(index) {
                varIds.append(index)
            }
            index+=1
        }
    }
    for i in varIds {
        if !varIdsUsed.contains(i) {
            var index = i
            var varr = ""
            while varIds.contains(index) {
                varr+=String(code[index])
                index+=1
                varIdsUsed.append(index)
            }
            vars.append(varr)
        }
    }
    for i in 0...code.count-1 {
        if numbIds.contains(i) && varIds.contains(i) {
            numbs.remove(at: numbIds.firstIndex(of: i)!)
            numbIds.remove(at: numbIds.firstIndex(of: i)!)
        }
    }
    var expression = [String]()
    var numbCount = 0
    var parenCount = 0
    var varCount = 0
    for i in 0...code.count-1 {
        if parenIds.contains(i) && !parenIdsUsed.contains(i) {
            expression.append(evaluate(code: parens[parenCount], space: space).value)
            parenCount+=1
        } else if varIds.contains(i) && !varIdsUsed.contains(i) && !parenIds.contains(i) {
            expression.append((getValue(variable: vars[varCount], space: space) as AnyObject).description)
            varCount+=1
        } else if numbIds.contains(i) && !numbIdsUsed.contains(i) && !parenIds.contains(i) && !varIds.contains(i) {
            expression.append(numbs[numbCount])
            numbCount+=1
        } else if code[i] == "+" && !parenIds.contains(i) {
            expression.append("+")
        } else if code[i] == "-" && !parenIds.contains(i) {
            expression.append("-")
        } else if code[i] == "*" && !parenIds.contains(i) {
            expression.append("*")
        } else if code[i] == "/" && !parenIds.contains(i) {
            expression.append("/")
        }
    }
    for i in 0...expression.count-1 {
        if expression[i] == "*" {
            expression[i+1] = String(Float(expression[i-1])!*Float(expression[i+1])!)
            expression[i-1] = ""
            expression[i] = ""
        } else if expression[i] == "/" {
            expression[i+1] = String(Float(expression[i-1])!/Float(expression[i+1])!)
            expression[i-1] = ""
            expression[i] = ""
        }
    }
    expression.removeAll { $0 == "" }
    if expression[0] == "-" {
        expression = ["0"] + expression
    }
    for i in 0...expression.count-1 {
        if expression[i] == "+" {
            expression[i+1] = String(Float(expression[i-1])!+Float(expression[i+1])!)
            expression[i] = ""
            expression[i-1] = ""
        } else if expression[i] == "-" {
            expression[i+1] = String(Float(expression[i-1])!-Float(expression[i+1])!)
            expression[i] = ""
            expression[i-1] = ""
        }
    }
    expression.removeAll { $0 == "" }
    return (expression[0], space)
}

func arrayReplaceHelper(arr: String, indexList: [Int], count: Int, newValue: String) -> String {
    var editedCode = ""
    var depth = 0
    for i in 0...arr.count-1 {
        if arr[i] == "[" {
            depth+=1
        } else if arr[i] == "]" {
            depth-=1
        }
        if arr[i] == "," && depth > 1 {
            editedCode+="\0"
        } else {
            editedCode+=String(arr[i])
        }
    }
    var arrayItems = editedCode.customReplace().dropFirst(1).dropLast(1).components(separatedBy: ",")
    for i in 0...arrayItems.count-1 {
        arrayItems[i] = arrayItems[i].replacingOccurrences(of: "\0", with: ",")
    }
    var output = ""
    if count == indexList.count-1 {
        for i in 0...arrayItems.count-1 {
            if i != 0 {
                output+=","
            }
            if i == indexList[count] {
                output+=newValue
            } else {
                output+=arrayItems[i]
            }
        }
        return "["+output+"]"
    } else {
        for i in 0...arrayItems.count-1 {
            if i != 0 {
                output+=","
            }
            if i == indexList[count] {
                output+=arrayReplaceHelper(arr: arrayItems[i], indexList: indexList, count: count+1, newValue: newValue)
            } else {
                output+=arrayItems[i]
            }
        }
        return "["+output+"]"
    }
}

func getValue(variable: String, space: [(name: String, value: Any, type: TypeValue, global: Bool)]) -> String {
    if let value = space.first(where: {variable == $0.name})?.value {
        if space.first(where: {variable == $0.name})?.type == TypeValue.String {
            return "\""+(value as AnyObject).description+"\""
        }
        return (value as AnyObject).description
    } else {
        return "very bad"
    }
}

func updateValue(variable: String, newValue: Any, space: [(name: String, value: Any, type: TypeValue, global: Bool)]) -> [(name: String, value: Any, type: TypeValue, global: Bool)] {
    var currentSpace = space
    let i = currentSpace.firstIndex(where: {variable == $0.name})
    currentSpace[i!].value = newValue
    return currentSpace
}

func getFunction(funcName: String, space: [(name: String, value: Any, type: TypeValue, global: Bool)]) -> Function {
    if let value = space.first(where: {funcName == $0.name})?.value {
        return value as! Function
    } else {
        return Function(params: [(name: "", type: TypeValue.String)], code: "", returnType: TypeValue.Void)
    }
}

func getVarNamesWithEquals(space: [(name: String, value: Any, type: TypeValue, global: Bool)]) -> [String] {
    var output = [String]()
    for i in space {
        if i.type != TypeValue.Function {
            output.append(i.name+"=")
        }
    }
    return output
}

func getVarNames(space: [(name: String, value: Any, type: TypeValue, global: Bool)]) -> [String] {
    var output = [String]()
    for i in space {
        if i.type != TypeValue.Function {
            output.append(i.name)
        }
    }
    return output
}

func getFunctionNames(space: [(name: String, value: Any, type: TypeValue, global: Bool)]) -> [String] {
    var output = [String]()
    for i in space {
        if i.type == TypeValue.Function {
            output.append(i.name)
        }
    }
    return output
}

func getType(variable: String) -> TypeValue {
    if variable.isNumber {
        return TypeValue.Float
    } else if variable[0] == "\"" && variable[variable.count-1] == "\"" {
        return TypeValue.String
    } else if variable.customReplace() == "true" || variable.customReplace() == "false" {
        return TypeValue.Boolean
    } else if variable[0] == "[" && variable[variable.count-1] == "]" {
        return TypeValue.Array
    } else {
        return TypeValue.TypeError
    }
}

var globalSpace = [(name: String, value: Any, type: TypeValue, global: Bool)]()

func run(code: String, space: [(name: String, value: Any, type: TypeValue, global: Bool)], global: Bool) -> (space: [(name: String, value: Any, type: TypeValue, global: Bool)], returnValue: String) {
    var currentSpace = space
    var bracketIds = [Int]()
    var depth = 0
    for i in 0...code.count-1 {
        if code[i] == "{" {
            if depth > 0 {
                bracketIds.append(i)
            }
            depth+=1
        } else if code[i] == "}" {
            depth-=1
            if depth != 0  {
                bracketIds.append(i)
            }
        } else if depth > 0 {
            bracketIds.append(i)
        }
    }
    var brackets = [String]()
    var bracketIdsUsed = [Int]()
    for i in bracketIds {
        if !bracketIdsUsed.contains(i) {
            var index = i
            var bracket = ""
            while bracketIds.contains(index) {
                bracket+=String(code[index])
                index+=1
                bracketIdsUsed.append(index)
            }
            brackets.append(bracket)
        }
    }
    var codeWithoutBrackets = ""
    for i in 0...code.count-1 {
        if !bracketIds.contains(i) {
            codeWithoutBrackets+=String(code[i])
        }
    }
    var bracketCount = 0
    let simpleCode = codeWithoutBrackets.replacingOccurrences(of: "\n", with: "").replacingOccurrences(of: "\t", with: "")
    let sets = simpleCode.components(separatedBy: ";")
    for set in sets {
        if set.hasPrefix("var ") && getType(variable: evaluate(code: set.dropFirst(4).components(separatedBy: "=")[1], space: currentSpace).value) == TypeValue.Float {
            let name = set.dropFirst(4).components(separatedBy: "=")[0].customReplace()
            if getVarNames(space: currentSpace).contains(name) {
                currentSpace = updateValue(variable: name, newValue: Float(evaluate(code: set.dropFirst(4).components(separatedBy: "=")[1], space: currentSpace).value)!, space: currentSpace)
                currentSpace = evaluate(code: set.dropFirst(4).components(separatedBy: "=")[1], space: currentSpace).space
            } else {
                currentSpace.append((name: name, value: Float(evaluate(code: set.dropFirst(4).components(separatedBy: "=")[1], space: currentSpace).value)!, type: TypeValue.Float, global: global))
                currentSpace = evaluate(code: set.dropFirst(4).components(separatedBy: "=")[1], space: currentSpace).space
            }
        } else if set.hasPrefix("var ") && getType(variable: evaluate(code: set.dropFirst(4).components(separatedBy: "=")[1], space: currentSpace).value) == TypeValue.String {
            let name = set.dropFirst(4).components(separatedBy: "=")[0].customReplace()
            if getVarNames(space: currentSpace).contains(name) {
                currentSpace = updateValue(variable: name, newValue: evaluate(code: set.dropFirst(4).components(separatedBy: "=")[1], space: currentSpace).value.dropFirst(1).dropLast(1), space: currentSpace)
                currentSpace = evaluate(code: set.dropFirst(4).components(separatedBy: "=")[1], space: currentSpace).space
            } else {
                currentSpace.append((name: name, value: evaluate(code: set.dropFirst(4).components(separatedBy: "=")[1], space: currentSpace).value.dropFirst(1).dropLast(1), type: TypeValue.String, global: global))
                currentSpace = evaluate(code: set.dropFirst(4).components(separatedBy: "=")[1], space: currentSpace).space
            }
        } else if set.hasPrefix("var ") && getType(variable: evaluate(code: set.dropFirst(4).components(separatedBy: "=")[1], space: currentSpace).value) == TypeValue.Boolean {
            let name = set.dropFirst(4).components(separatedBy: "=")[0].customReplace()
            if getVarNames(space: currentSpace).contains(name) {
                currentSpace = updateValue(variable: name, newValue: evaluate(code: set.dropFirst(4).components(separatedBy: "=")[1], space: currentSpace), space: currentSpace)
                currentSpace = evaluate(code: set.dropFirst(4).components(separatedBy: "=")[1], space: currentSpace).space
            } else {
                currentSpace.append((name: name, value: evaluate(code: set.dropFirst(4).components(separatedBy: "=")[1], space: currentSpace), type: TypeValue.Boolean, global: global))
                currentSpace = evaluate(code: set.dropFirst(4).components(separatedBy: "=")[1], space: currentSpace).space
            }
        } else if set.hasPrefix("var ") && getType(variable: evaluate(code: set.dropFirst(4).components(separatedBy: "=")[1], space: currentSpace).value) == TypeValue.Array {
            let name = set.dropFirst(4).components(separatedBy: "=")[0].customReplace()
            if getVarNames(space: currentSpace).contains(name) {
                currentSpace = updateValue(variable: name, newValue: evaluate(code: set.dropFirst(4).components(separatedBy: "=")[1], space: currentSpace), space: currentSpace)
                currentSpace = evaluate(code: set.dropFirst(4).components(separatedBy: "=")[1], space: currentSpace).space
            } else {
                currentSpace.append((name: name, value: evaluate(code: set.dropFirst(4).components(separatedBy: "=")[1], space: currentSpace), type: TypeValue.Array, global: global))
                currentSpace = evaluate(code: set.dropFirst(4).components(separatedBy: "=")[1], space: currentSpace).space
            }
        } else if set.customReplace().hasPrefix("print(") && set[set.count-1] == ")" {
            if getType(variable: evaluate(code: String(set.customReplace().dropFirst(6).dropLast(1)), space: currentSpace).value) == TypeValue.Float {
                print(Float(evaluate(code: String(set.customReplace().dropFirst(6).dropLast(1)), space: currentSpace).value)!)
                currentSpace = evaluate(code: String(set.customReplace().dropFirst(6).dropLast(1)), space: currentSpace).space
            } else if getType(variable: evaluate(code: String(set.customReplace().dropFirst(6).dropLast(1)), space: currentSpace).value) == TypeValue.String {
                print(evaluate(code: String(set.customReplace().dropFirst(6).dropLast(1)), space: currentSpace).value.dropFirst(1).dropLast(1))
                currentSpace = evaluate(code: String(set.customReplace().dropFirst(6).dropLast(1)), space: currentSpace).space
            } else if getType(variable: evaluate(code: String(set.customReplace().dropFirst(6).dropLast(1)), space: currentSpace).value) == TypeValue.Boolean {
                print(evaluate(code: String(set.customReplace().dropFirst(6).dropLast(1)), space: currentSpace).value)
                currentSpace = evaluate(code: String(set.customReplace().dropFirst(6).dropLast(1)), space: currentSpace).space
            } else if getType(variable: evaluate(code: String(set.customReplace().dropFirst(6).dropLast(1)), space: currentSpace).value) == TypeValue.Array {
                print(evaluate(code: String(set.customReplace().dropFirst(6).dropLast(1)), space: currentSpace).value)
                currentSpace = evaluate(code: String(set.customReplace().dropFirst(6).dropLast(1)), space: currentSpace).space
            }
        } else if set.hasPrefix("function ") && set.contains("(") && set.customReplace().hasSuffix("){}") {
            let funcName = set.dropFirst(9).components(separatedBy: "(")[0]
            let funcParam = set.customReplace().dropFirst(9+funcName.count).dropLast(3).components(separatedBy: ",")
            var funcParamSplit = [(name: String, type: TypeValue)]()
            if funcParam[0].count > 0 {
                for i in funcParam {
                    if i.components(separatedBy: ":")[1] == "String" {
                        funcParamSplit.append((name: i.components(separatedBy: ":")[0], type: TypeValue.String))
                    } else if i.components(separatedBy: ":")[1] == "Float" {
                        funcParamSplit.append((name: i.components(separatedBy: ":")[0], type: TypeValue.Float))
                    } else if i.components(separatedBy: ":")[1] == "Boolean" {
                        funcParamSplit.append((name: i.components(separatedBy: ":")[0], type: TypeValue.Boolean))
                    } else if i.components(separatedBy: ":")[1] == "Array" {
                        funcParamSplit.append((name: i.components(separatedBy: ":")[0], type: TypeValue.Array))
                    }
                }
            }
            currentSpace.append((name: funcName, value: Function(params: funcParamSplit, code: brackets[bracketCount], returnType: TypeValue.Void), type: TypeValue.Function, global: global))
            bracketCount+=1
        } else if set.hasPrefix("function ") && set.contains("(") && set.customReplace().contains("->") && set.customReplace().hasSuffix("{}") {
            let funcName = set.dropFirst(9).components(separatedBy: "(")[0]
            let funcParam = set.customReplace().dropFirst(9+funcName.count).dropLast(set.customReplace().components(separatedBy: "->")[1].dropLast(2).count+5).components(separatedBy: ",")
            var returnType = TypeValue.Void
            if String(set.customReplace().components(separatedBy: "->")[1].dropLast(2)) == "String" {
                returnType = TypeValue.String
            } else if String(set.customReplace().components(separatedBy: "->")[1].dropLast(2)) == "Float" {
                returnType = TypeValue.Float
            } else if String(set.customReplace().components(separatedBy: "->")[1].dropLast(2)) == "Boolean" {
                returnType = TypeValue.Boolean
            } else if String(set.customReplace().components(separatedBy: "->")[1].dropLast(2)) == "Array" {
                returnType = TypeValue.Array
            }
            var funcParamSplit = [(name: String, type: TypeValue)]()
            if funcParam[0].count > 0 {
                for i in funcParam {
                    if i.components(separatedBy: ":")[1] == "String" {
                        funcParamSplit.append((name: i.components(separatedBy: ":")[0], type: TypeValue.String))
                    } else if i.components(separatedBy: ":")[1] == "Float" {
                        funcParamSplit.append((name: i.components(separatedBy: ":")[0], type: TypeValue.Float))
                    } else if i.components(separatedBy: ":")[1] == "Boolean" {
                        funcParamSplit.append((name: i.components(separatedBy: ":")[0], type: TypeValue.Boolean))
                    } else if i.components(separatedBy: ":")[1] == "Array" {
                        funcParamSplit.append((name: i.components(separatedBy: ":")[0], type: TypeValue.Array))
                    }
                }
            }
            currentSpace.append((name: funcName, value: Function(params: funcParamSplit, code: brackets[bracketCount], returnType: returnType), type: TypeValue.Function, global: global))
            bracketCount+=1
        } else if getVarNamesWithEquals(space: currentSpace).contains(where: set.customReplace().hasPrefix) {
            if getType(variable: evaluate(code: set.components(separatedBy: "=")[1], space: currentSpace).value) == TypeValue.Float {
                let newValue = Float(evaluate(code: set.components(separatedBy: "=")[1], space: currentSpace).value)
                let variable = set.components(separatedBy: "=")[0].customReplace()
                currentSpace = updateValue(variable: variable, newValue: newValue!, space: currentSpace)
                currentSpace = evaluate(code: set.components(separatedBy: "=")[1], space: currentSpace).space
            } else if getType(variable: evaluate(code: set.components(separatedBy: "=")[1], space: currentSpace).value) == TypeValue.String {
                let newValue = evaluate(code: set.components(separatedBy: "=")[1], space: currentSpace).value.dropFirst(1).dropLast(1)
                let variable = set.components(separatedBy: "=")[0].customReplace()
                currentSpace = updateValue(variable: variable, newValue: newValue, space: currentSpace)
                currentSpace = evaluate(code: set.components(separatedBy: "=")[1], space: currentSpace).space
            } else if getType(variable: evaluate(code: set.components(separatedBy: "=")[1], space: currentSpace).value) == TypeValue.Boolean {
                let newValue = evaluate(code: set.components(separatedBy: "=")[1], space: currentSpace).value
                let variable = set.components(separatedBy: "=")[0].customReplace()
                currentSpace = updateValue(variable: variable, newValue: newValue, space: currentSpace)
                currentSpace = evaluate(code: set.components(separatedBy: "=")[1], space: currentSpace).space
            } else if getType(variable: evaluate(code: set.components(separatedBy: "=")[1], space: currentSpace).value) == TypeValue.Array {
                let newValue = evaluate(code: set.components(separatedBy: "=")[1], space: currentSpace).value
                let variable = set.components(separatedBy: "=")[0].customReplace()
                currentSpace = updateValue(variable: variable, newValue: newValue, space: currentSpace)
                currentSpace = evaluate(code: set.components(separatedBy: "=")[1], space: currentSpace).space
            }
        } else if getFunctionNames(space: currentSpace).contains(where: set.customReplace().hasPrefix) && set.contains("(") && set.contains(")") {
            var localSpace = [(name: String, value: Any, type: TypeValue, global: Bool)]()
            let funcName = set.customReplace().components(separatedBy: "(")[0]
            let funcParam = set.customReplace().dropLast(1).components(separatedBy: "(")[1].components(separatedBy: ",")
            if funcParam[0].count > 0 {
                for i in funcParam {
                    if getType(variable: evaluate(code: i.components(separatedBy: ":")[1], space: currentSpace).value) == TypeValue.String {
                        localSpace.append((name: String(i.components(separatedBy: ":")[0]), value: evaluate(code: i.components(separatedBy: ":")[1], space: currentSpace).value, type: TypeValue.String, global: false))
                    } else if getType(variable: evaluate(code: i.components(separatedBy: ":")[1], space: currentSpace).value) == TypeValue.Float {
                        localSpace.append((name: i.components(separatedBy: ":")[0], value: Float(evaluate(code: i.components(separatedBy: ":")[1], space: currentSpace).value)!, type: TypeValue.Float, global: false))
                    } else if getType(variable: evaluate(code: i.components(separatedBy: ":")[1], space: currentSpace).value) == TypeValue.Boolean {
                        localSpace.append((name: i.components(separatedBy: ":")[0], value: evaluate(code: i.components(separatedBy: ":")[1], space: currentSpace).value, type: TypeValue.Boolean, global: false))
                    } else if getType(variable: evaluate(code: i.components(separatedBy: ":")[1], space: currentSpace).value) == TypeValue.Array {
                        localSpace.append((name: i.components(separatedBy: ":")[0], value: evaluate(code: i.components(separatedBy: ":")[1], space: currentSpace).value, type: TypeValue.Array, global: false))
                    }
                }
            }
            let functionValue = getFunction(funcName: funcName, space: currentSpace)
            var paramsValid = true
            if functionValue.params.count > 1 {
                for i in 0...functionValue.params.count-1 {
                    if functionValue.params[i].name != localSpace[i].name || functionValue.params[i].type != localSpace[i].type {
                        paramsValid = false
                    }
                }
            }
            if paramsValid {
                for i in currentSpace {
                    localSpace.append(i)
                }
                currentSpace = run(code: functionValue.code, space: localSpace, global: false).space
                let tempCount = currentSpace.count-1
                for i in 0...currentSpace.count-1 {
                    if !currentSpace[tempCount-i].global {
                        currentSpace.remove(at: tempCount-i)
                    }
                }
            }
        } else if set.customReplace().hasPrefix("return") {
            return (currentSpace, evaluate(code: String(set.customReplace().dropFirst(6)), space: currentSpace).value)
        } else if set.customReplace().hasPrefix("if(") && getType(variable: evaluate(code: String(set.customReplace().dropFirst(3).components(separatedBy: "{")[0].dropLast(1)), space: currentSpace).value) == TypeValue.Boolean {
            var finished = false
            if evaluate(code: String(set.customReplace().dropFirst(3).components(separatedBy: "{")[0].dropLast(1)), space: currentSpace).value == "true" {
                currentSpace = run(code: brackets[bracketCount], space: currentSpace, global: global).space
                bracketCount+=1
                finished = true
            } else {
                bracketCount+=1
                if set.contains("elif") {
                    for i in 1...set.components(separatedBy: "elif").count-1 {
                        if !finished && evaluate(code: String(set.customReplace().components(separatedBy: "elif")[i].dropFirst(1).components(separatedBy: "{")[0].dropLast(1)), space: currentSpace).value == "true" {
                            currentSpace = run(code: brackets[bracketCount], space: currentSpace, global: global).space
                            bracketCount+=1
                            finished = true
                        } else {
                            bracketCount+=1
                        }
                    }
                }
                if set.contains("else") && !finished {
                    currentSpace = run(code: brackets[bracketCount], space: currentSpace, global: global).space
                    bracketCount+=1
                }
            }
        } else if getVarNames(space: currentSpace).contains(where: set.customReplace().components(separatedBy: "[")[0].hasPrefix) {
            if getType(variable: evaluate(code: set.customReplace().components(separatedBy: "[")[0], space: currentSpace).value) == TypeValue.String {
                let oldValue = evaluate(code: set.customReplace().components(separatedBy: "[")[0], space: currentSpace).value.dropFirst(1).dropLast(1)
                let index = Int(evaluate(code: String(set.customReplace().components(separatedBy: "=")[0].components(separatedBy: "[")[1].dropLast(1)), space: currentSpace).value)!
                var newValue = ""
                for i in 0...oldValue.count-1 {
                    if i != index {
                        newValue+=String(oldValue[i])
                    } else {
                        newValue+=evaluate(code: set.components(separatedBy: "=")[1], space: currentSpace).value.dropFirst(1).dropLast(1)
                    }
                }
                let variable = set.components(separatedBy: "[")[0].customReplace()
                currentSpace = updateValue(variable: variable, newValue: newValue, space: currentSpace)
                currentSpace = evaluate(code: set.customReplace().components(separatedBy: "[")[0], space: currentSpace).space
            } else if getType(variable: evaluate(code: set.customReplace().components(separatedBy: "[")[0], space: currentSpace).value) == TypeValue.Array {
                var indexList = set.customReplace().components(separatedBy: "=")[0].components(separatedBy: "[")
                indexList.remove(at: 0)
                for i in 0...indexList.count-1 {
                    indexList[i] = String(indexList[i].dropLast(1))
                }
                var intIndexList = [Int]()
                for i in indexList {
                    intIndexList.append(Int(i)!)
                }
                let arr = evaluate(code: set.customReplace().components(separatedBy: "[")[0], space: currentSpace).value
                let newValue = arrayReplaceHelper(arr: arr, indexList: intIndexList, count: 0, newValue: String(evaluate(code: set.components(separatedBy: "=")[1], space: currentSpace).value))
                let variable = set.components(separatedBy: "[")[0].customReplace()
                currentSpace = updateValue(variable: variable, newValue: newValue, space: currentSpace)
            }
        } else if set.customReplace().hasPrefix("for(") && set.contains(" in ") && set.contains(")") {
            let newVarName = set.components(separatedBy: " in ")[0].customReplace().dropFirst(4)
            var range = [String]()
            if set.contains("...") {
                let lowerBound = Int(evaluate(code: set.components(separatedBy: " in ")[1].components(separatedBy: "...")[0].customReplace(), space: currentSpace).value)!
                let upperBound = Int(evaluate(code: String(set.components(separatedBy: " in ")[1].components(separatedBy: "...")[1].customReplace().dropLast(3)), space: currentSpace).value)!
                for i in lowerBound...upperBound {
                    range.append(String(i))
                }
            } else if getType(variable: evaluate(code: String(set.components(separatedBy: " in ")[1].customReplace().dropLast(3)), space: currentSpace).value) == TypeValue.String {
                for i in evaluate(code: String(set.components(separatedBy: " in ")[1].customReplace().dropLast(3)), space: currentSpace).value {
                    range.append(String(i))
                }
                range.removeFirst()
                range.removeLast()
            } else if getType(variable: evaluate(code: String(set.components(separatedBy: " in ")[1].customReplace().dropLast(3)), space: currentSpace).value) == TypeValue.Array {
                let arr = evaluate(code: String(set.components(separatedBy: " in ")[1].customReplace().dropLast(3)), space: currentSpace).value
                var editedCode = ""
                var depth = 0
                for i in 0...arr.count-1 {
                    if arr[i] == "[" {
                        depth+=1
                    } else if arr[i] == "]" {
                        depth-=1
                    }
                    if arr[i] == "," && depth > 1 {
                        editedCode+="\0"
                    } else {
                        editedCode+=String(arr[i])
                    }
                }
                var arrayItems = editedCode.customReplace().dropFirst(1).dropLast(1).components(separatedBy: ",")
                for i in 0...arrayItems.count-1 {
                    arrayItems[i] = arrayItems[i].replacingOccurrences(of: "\0", with: ",")
                }
                for i in arrayItems {
                    range.append(i)
                }
            }
            for i in range {
                if getType(variable: evaluate(code: i, space: currentSpace).value) == TypeValue.String && i.count > 1 {
                    currentSpace.append((name: String(newVarName), value: i.dropFirst(1).dropLast(1), type: getType(variable: evaluate(code: i, space: currentSpace).value), global: global))
                } else {
                    currentSpace.append((name: String(newVarName), value: i, type: getType(variable: evaluate(code: i, space: currentSpace).value), global: global))
                }
                currentSpace = run(code: brackets[bracketCount], space: currentSpace, global: global).space
                currentSpace.removeAll { $0.name == newVarName }
            }
            bracketCount+=1
        } else if set.customReplace().hasPrefix("while(") && getType(variable: evaluate(code: String(set.customReplace().dropFirst(6).dropLast(3)), space: currentSpace).value) == TypeValue.Boolean {
            while evaluate(code: String(set.customReplace().dropFirst(6).dropLast(3)), space: currentSpace).value == "true" {
                currentSpace = run(code: brackets[bracketCount], space: currentSpace, global: global).space
            }
            bracketCount+=1
            
        }
    }
    return (currentSpace, "\0")
}

var code = """
function do(a: Float) -> Float {
 print(a);
 if(a < 10) {
     return do(a:a+1);
 } else {
     return a;
 };
};
print(do(a: 0));
"""
//Add other array functions (append, remove) and concatinate arrays
//Ability to cast
//Store return of functions better for recursion
//Throw errors?
globalSpace = run(code: code, space: globalSpace, global: true).space


