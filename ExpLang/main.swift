//
//  main.swift
//  ExpLang
//
//  Created by Jack Frank on 3/18/23.
//

import Foundation

extension String {
    var isNumber: Bool {
        let digitsCharacters = CharacterSet(charactersIn: ".0123456789")
        return CharacterSet(charactersIn: self).isSubset(of: digitsCharacters)
    }
}

extension StringProtocol {
    subscript(offset: Int) -> Character {
        self[index(startIndex, offsetBy: offset)]
    }
}

enum TypeValue {
    case String
    case Float
    case Boolean
    case Array
    case Function
    case TypeError
}

struct Function {
    var params: [(name: String, type: TypeValue)]
    var code: String
}

func evaluate(code: String, space: [(name: String, value: Any, type: TypeValue)]) -> String {
    if getVarNames(space: space).contains(code) {
        return evaluate(code: getValue(variable: code, space: space), space: space)
    }
    if code.components(separatedBy: "[").count == 2 && code.components(separatedBy: "]").count == 2 && code.replacingOccurrences(of: " ", with: "")[0] == "[" && code.replacingOccurrences(of: " ", with: "")[code.replacingOccurrences(of: " ", with: "").count-1] == "]"{
        var arrayItems = code.replacingOccurrences(of: " ", with: "").dropFirst(1).dropLast(1).components(separatedBy: ",")
        for i in 0...arrayItems.count-1 {
            arrayItems[i] = evaluate(code: arrayItems[i], space: space)
        }
        var output = "["
        for i in 0...arrayItems.count-1 {
            output+=arrayItems[i]
            if i != arrayItems.count-1 {
                output+=","
            }
        }
        output+="]"
        return output
    }
    if (code.components(separatedBy: "[").count > 2 && code.components(separatedBy: "]").count > 2) || (code.contains("[") && getType(variable: evaluate(code: code.components(separatedBy: "[")[0].replacingOccurrences(of: " ", with: ""), space: space)) == TypeValue.Array) {
        if code.components(separatedBy: "[").count > 2 && code.components(separatedBy: "]").count > 2 {
            let evaluatedArray = evaluate(code: code.components(separatedBy: "]")[0]+"]", space: space)
            let arrayItems = evaluatedArray.replacingOccurrences(of: " ", with: "").dropFirst(1).dropLast(1).components(separatedBy: ",")
            let index = Int(evaluate(code: String(code.replacingOccurrences(of: " ", with: "").components(separatedBy: "]")[1].dropFirst(1)), space: space))!
            return arrayItems[index]
        } else {
            let evaluatedArray = evaluate(code: code.components(separatedBy: "[")[0].replacingOccurrences(of: " ", with: ""), space: space)
            let arrayItems = evaluatedArray.replacingOccurrences(of: " ", with: "").dropFirst(1).dropLast(1).components(separatedBy: ",")
            let index = Int(evaluate(code: String(code.replacingOccurrences(of: " ", with: "").components(separatedBy: "[")[1].dropLast(1)), space: space))!
            return arrayItems[index]
        }
    }
    if code.replacingOccurrences(of: " ", with: "") == "true" || code.replacingOccurrences(of: " ", with: "") == "false" {
        return String(code.replacingOccurrences(of: " ", with: ""))
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
            } else if code[i] != " " && code[i] != ">" && code[i] != "<" && code[i] != "=" && code[i] != "!" && code[i] != "|" && code[i] != "&" && depth == 0 {
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
                expression.append(evaluate(code: parens[parenCount], space: space))
                parenCount+=1
            } else if valIds.contains(i) && !valIdsUsed.contains(i) && !parenIds.contains(i) {
                expression.append(evaluate(code: vals[valCount], space: space))
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
                if expression[i-1] < expression[i+1] {
                    expression[i] = "true"
                } else {
                    expression[i] = "false"
                }
                expression[i-1] = ""
                expression[i+1] = ""
            } else if expression[i] == ">" {
                if expression[i-1] > expression[i+1] {
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
                if expression[i-1] <= expression[i+1] {
                    expression[i] = "true"
                } else {
                    expression[i] = "false"
                }
                expression[i-1] = ""
                expression[i+1] = ""
            } else if expression[i] == ">=" {
                if expression[i-1] >= expression[i+1] {
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
        return expression[0]
    }
    if !code.contains("\"") && !code.contains("+") && !code.contains("-") && !code.contains("*") && !code.contains("/") && !code.contains("(") && !code.contains(")") && !code.isNumber && getType(variable: getValue(variable: code, space: space)) == TypeValue.Boolean {
        return evaluate(code: getValue(variable: code.replacingOccurrences(of: " ", with: ""), space: space), space: space)
    }
    if !code.contains("\"") && !code.contains("+") && !code.contains("-") && !code.contains("*") && !code.contains("/") && !code.contains("(") && !code.contains(")") && code.replacingOccurrences(of: " ", with: "").isNumber {
        return code.replacingOccurrences(of: " ", with: "")
    } else if !code.contains("\"") && !code.contains("-") && !code.contains("*") && !code.contains("/") && !code.contains("(") && !code.contains(")") {
        var simpleAdds: Float = 0.0
        let splitByPlus = code.components(separatedBy: "+")
        var allNumbers = true
        for i in splitByPlus {
            if i.replacingOccurrences(of: " ", with: "").isNumber {
                simpleAdds+=Float(i.replacingOccurrences(of: " ", with: ""))!
            } else {
                allNumbers = false
            }
        }
        if allNumbers {
            return String(simpleAdds)
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
        return "\""+output+"\""
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
            expression.append(evaluate(code: parens[parenCount], space: space))
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
    return expression[0]
}

func getValue(variable: String, space: [(name: String, value: Any, type: TypeValue)]) -> String {
    if let value = space.first(where: {variable == $0.name})?.value {
        if space.first(where: {variable == $0.name})?.type == TypeValue.String {
            return "\""+(value as AnyObject).description+"\""
        }
        return (value as AnyObject).description
    } else {
        return "very bad"
    }
}

func updateValue(variable: String, newValue: Any, space: [(name: String, value: Any, type: TypeValue)]) -> [(name: String, value: Any, type: TypeValue)] {
    var currentSpace = space
    let i = currentSpace.firstIndex(where: {variable == $0.name})
    currentSpace[i!].value = newValue
    return currentSpace
}

func getFunction(funcName: String, space: [(name: String, value: Any, type: TypeValue)]) -> Function {
    if let value = space.first(where: {funcName == $0.name})?.value {
        return value as! Function
    } else {
        return Function(params: [(name: "", type: TypeValue.String)], code: "")
    }
}

func getVarNamesWithEquals(space: [(name: String, value: Any, type: TypeValue)]) -> [String] {
    var output = [String]()
    for i in space {
        if i.type != TypeValue.Function {
            output.append(i.name+"=")
        }
    }
    return output
}

func getVarNames(space: [(name: String, value: Any, type: TypeValue)]) -> [String] {
    var output = [String]()
    for i in space {
        if i.type != TypeValue.Function {
            output.append(i.name)
        }
    }
    return output
}

func getFunctionNames(space: [(name: String, value: Any, type: TypeValue)]) -> [String] {
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
    } else if variable.replacingOccurrences(of: " ", with: "") == "true" || variable.replacingOccurrences(of: " ", with: "") == "false" {
        return TypeValue.Boolean
    } else if variable[0] == "[" && variable[variable.count-1] == "]" {
        return TypeValue.Array
    } else {
        return TypeValue.TypeError
    }
}

var globalSpace = [(name: String, value: Any, type: TypeValue)]()

func run(code: String, space: [(name: String, value: Any, type: TypeValue)]) {
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
    let simpleCode = codeWithoutBrackets.replacingOccurrences(of: "\n", with: "")
    let sets = simpleCode.components(separatedBy: ";")
    for set in sets {
        if set.hasPrefix("var ") && getType(variable: evaluate(code: set.dropFirst(4).components(separatedBy: "=")[1], space: currentSpace)) == TypeValue.Float {
            let name = set.dropFirst(4).components(separatedBy: "=")[0].replacingOccurrences(of: " ", with: "")
            currentSpace.append((name: name, value: Float(evaluate(code: set.dropFirst(4).components(separatedBy: "=")[1], space: currentSpace))!, type: TypeValue.Float))
        } else if set.hasPrefix("var ") && getType(variable: evaluate(code: set.dropFirst(4).components(separatedBy: "=")[1], space: currentSpace)) == TypeValue.String {
            let name = set.dropFirst(4).components(separatedBy: "=")[0].replacingOccurrences(of: " ", with: "")
            currentSpace.append((name: name, value: evaluate(code: set.dropFirst(4).components(separatedBy: "=")[1], space: currentSpace).dropFirst(1).dropLast(1), type: TypeValue.String))
        } else if set.hasPrefix("var ") && getType(variable: evaluate(code: set.dropFirst(4).components(separatedBy: "=")[1], space: currentSpace)) == TypeValue.Boolean {
            let name = set.dropFirst(4).components(separatedBy: "=")[0].replacingOccurrences(of: " ", with: "")
            currentSpace.append((name: name, value: evaluate(code: set.dropFirst(4).components(separatedBy: "=")[1], space: currentSpace), type: TypeValue.Boolean))
        } else if set.hasPrefix("var ") && getType(variable: evaluate(code: set.dropFirst(4).components(separatedBy: "=")[1], space: currentSpace)) == TypeValue.Array {
            let name = set.dropFirst(4).components(separatedBy: "=")[0].replacingOccurrences(of: " ", with: "")
            currentSpace.append((name: name, value: evaluate(code: set.dropFirst(4).components(separatedBy: "=")[1], space: currentSpace), type: TypeValue.Array))
        } else if set.hasPrefix("print(") && set[set.count-1] == ")" {
            if getType(variable: evaluate(code: String(set.dropFirst(6).dropLast(1)), space: currentSpace)) == TypeValue.Float {
                print(Float(evaluate(code: String(set.dropFirst(6).dropLast(1)), space: currentSpace))!)
            } else if getType(variable: evaluate(code: String(set.dropFirst(6).dropLast(1)), space: currentSpace)) == TypeValue.String {
                print(evaluate(code: String(set.dropFirst(6).dropLast(1)), space: currentSpace).dropFirst(1).dropLast(1))
            } else if getType(variable: evaluate(code: String(set.dropFirst(6).dropLast(1)), space: currentSpace)) == TypeValue.Boolean {
                print(evaluate(code: String(set.dropFirst(6).dropLast(1)), space: currentSpace))
            } else if getType(variable: evaluate(code: String(set.dropFirst(6).dropLast(1)), space: currentSpace)) == TypeValue.Array {
                print(evaluate(code: String(set.dropFirst(6).dropLast(1)), space: currentSpace))
            }
        } else if set.hasPrefix("function ") && set.contains("(") && set.replacingOccurrences(of: " ", with: "").hasSuffix("){}") {
            let funcName = set.dropFirst(9).components(separatedBy: "(")[0]
            let funcParam = set.replacingOccurrences(of: " ", with: "").dropFirst(9+funcName.count).dropLast(3).components(separatedBy: ",")
            var funcParamSplit = [(name: String, type: TypeValue)]()
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
            currentSpace.append((name: funcName, value: Function(params: funcParamSplit, code: brackets[bracketCount]), type: TypeValue.Function))
            bracketCount+=1
        } else if getVarNamesWithEquals(space: currentSpace).contains(where: set.replacingOccurrences(of: " ", with: "").hasPrefix) {
            if getType(variable: evaluate(code: set.components(separatedBy: "=")[1], space: currentSpace)) == TypeValue.Float {
                let newValue = Float(evaluate(code: set.components(separatedBy: "=")[1], space: currentSpace))
                let variable = set.components(separatedBy: "=")[0].replacingOccurrences(of: " ", with: "")
                currentSpace = updateValue(variable: variable, newValue: newValue!, space: currentSpace)
            } else if getType(variable: evaluate(code: set.components(separatedBy: "=")[1], space: currentSpace)) == TypeValue.String {
                let newValue = evaluate(code: set.components(separatedBy: "=")[1], space: currentSpace).dropFirst(1).dropLast(1)
                let variable = set.components(separatedBy: "=")[0].replacingOccurrences(of: " ", with: "")
                currentSpace = updateValue(variable: variable, newValue: newValue, space: currentSpace)
            } else if getType(variable: evaluate(code: set.components(separatedBy: "=")[1], space: currentSpace)) == TypeValue.Boolean {
                let newValue = evaluate(code: set.components(separatedBy: "=")[1], space: currentSpace)
                let variable = set.components(separatedBy: "=")[0].replacingOccurrences(of: " ", with: "")
                currentSpace = updateValue(variable: variable, newValue: newValue, space: currentSpace)
            } else if getType(variable: evaluate(code: set.components(separatedBy: "=")[1], space: currentSpace)) == TypeValue.Array {
                let newValue = evaluate(code: set.components(separatedBy: "=")[1], space: currentSpace)
                let variable = set.components(separatedBy: "=")[0].replacingOccurrences(of: " ", with: "")
                currentSpace = updateValue(variable: variable, newValue: newValue, space: currentSpace)
            }
        } else if getFunctionNames(space: currentSpace).contains(where: set.replacingOccurrences(of: " ", with: "").hasPrefix) && set.contains("(") && set.contains(")") {
            var localSpace = [(name: String, value: Any, type: TypeValue)]()
            let funcName = set.replacingOccurrences(of: " ", with: "").components(separatedBy: "(")[0]
            let funcParam = set.replacingOccurrences(of: " ", with: "").dropLast(1).components(separatedBy: "(")[1].components(separatedBy: ",")
            for i in funcParam {
                if getType(variable: evaluate(code: i.components(separatedBy: ":")[1], space: currentSpace)) == TypeValue.String {
                    localSpace.append((name: String(i.components(separatedBy: ":")[0]), value: evaluate(code: i.components(separatedBy: ":")[1], space: currentSpace), type: TypeValue.String))
                } else if getType(variable: evaluate(code: i.components(separatedBy: ":")[1], space: currentSpace)) == TypeValue.Float {
                    localSpace.append((name: i.components(separatedBy: ":")[0], value: Float(evaluate(code: i.components(separatedBy: ":")[1], space: currentSpace))!, type: TypeValue.Float))
                } else if getType(variable: evaluate(code: i.components(separatedBy: ":")[1], space: currentSpace)) == TypeValue.Boolean {
                    localSpace.append((name: i.components(separatedBy: ":")[0], value: evaluate(code: i.components(separatedBy: ":")[1], space: currentSpace), type: TypeValue.Boolean))
                } else if getType(variable: evaluate(code: i.components(separatedBy: ":")[1], space: currentSpace)) == TypeValue.Array {
                    localSpace.append((name: i.components(separatedBy: ":")[0], value: evaluate(code: i.components(separatedBy: ":")[1], space: currentSpace), type: TypeValue.Array))
                }
            }
            let functionValue = getFunction(funcName: funcName, space: currentSpace)
            var paramsValid = true
            for i in 0...functionValue.params.count-1 {
                if functionValue.params[i].name != localSpace[i].name || functionValue.params[i].type != localSpace[i].type {
                    paramsValid = false
                }
            }
            if paramsValid {
                for i in currentSpace {
                    localSpace.append(i)
                }
                run(code: functionValue.code, space: localSpace)
            }
        } else if set.replacingOccurrences(of: " ", with: "").hasPrefix("if(") && getType(variable: evaluate(code: String(set.replacingOccurrences(of: " ", with: "").dropFirst(3).components(separatedBy: "{")[0].dropLast(1)), space: currentSpace)) == TypeValue.Boolean {
            var finished = false
            if evaluate(code: String(set.replacingOccurrences(of: " ", with: "").dropFirst(3).components(separatedBy: "{")[0].dropLast(1)), space: currentSpace) == "true" {
                run(code: brackets[bracketCount], space: currentSpace)
                bracketCount+=1
                finished = true
            } else {
                bracketCount+=1
                if set.contains("elif") {
                    for i in 1...set.components(separatedBy: "elif").count-1 {
                        if !finished && evaluate(code: String(set.replacingOccurrences(of: " ", with: "").components(separatedBy: "elif")[i].dropFirst(1).components(separatedBy: "{")[0].dropLast(1)), space: currentSpace) == "true" {
                            run(code: brackets[bracketCount], space: currentSpace)
                            bracketCount+=1
                            finished = true
                        } else {
                            bracketCount+=1
                        }
                    }
                }
                if set.contains("else") && !finished {
                    run(code: brackets[bracketCount], space: currentSpace)
                    bracketCount+=1
                }
            }
        }
    }
}

var code = """
var arr = ["jejej",[1+2,"jwj"]][1];
print(arr);
""" //missing higher dimensional array functionality
run(code: code, space: globalSpace)
