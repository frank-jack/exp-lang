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
    case Function
    case TypeError
}

struct Function {
    var params: [(name: String, type: TypeValue)]
    var code: String
}

func evaluate(code: String, space: [(name: String, value: Any, type: TypeValue)]) -> String {
    if code.contains("\"") { //Cannot have statements without ""
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
                    trueCode+=getValue(variable: tempVarName, space: space) as! String
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
    /*print("numbIds: "+numbIds.description)
    print("numbs: "+numbs.description)
    print("parenIds: "+parenIds.description)
    print("parens: "+parens.description)
    print("varIds: "+varIds.description)
    print("vars: "+vars.description)*/
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
    //print(expression)
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

func getValue(variable: String, space: [(name: String, value: Any, type: TypeValue)]) -> Any {
    if let value = space.first(where: {variable == $0.name})?.value {
        return value
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
    //print(brackets)
    //print(bracketIds)
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
        } else if set.hasPrefix("print(") && set[set.count-1] == ")" {
            if getType(variable: evaluate(code: String(set.dropFirst(6).dropLast(1)), space: currentSpace)) == TypeValue.Float {
                print(Float(evaluate(code: String(set.dropFirst(6).dropLast(1)), space: currentSpace))!)
            } else if getType(variable: evaluate(code: String(set.dropFirst(6).dropLast(1)), space: currentSpace)) == TypeValue.String {
                print(evaluate(code: String(set.dropFirst(6).dropLast(1)), space: currentSpace).dropFirst(1).dropLast(1))
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
            }
        } else if getFunctionNames(space: currentSpace).contains(where: set.replacingOccurrences(of: " ", with: "").hasPrefix) && set.contains("(") && set.contains(")") {
            var localSpace = [(name: String, value: Any, type: TypeValue)]()
            let funcName = set.replacingOccurrences(of: " ", with: "").components(separatedBy: "(")[0]
            let funcParam = set.replacingOccurrences(of: " ", with: "").dropLast(1).components(separatedBy: "(")[1].components(separatedBy: ",")
            //print(funcParam)
            for i in funcParam {
                if getType(variable: evaluate(code: i.components(separatedBy: ":")[1], space: currentSpace)) == TypeValue.String {
                    localSpace.append((name: String(i.components(separatedBy: ":")[0]), value: i.components(separatedBy: ":")[1], type: TypeValue.String))
                } else if getType(variable: evaluate(code: i.components(separatedBy: ":")[1], space: currentSpace)) == TypeValue.Float {
                    localSpace.append((name: i.components(separatedBy: ":")[0], value: Float(evaluate(code: i.components(separatedBy: ":")[1], space: currentSpace))!, type: TypeValue.Float))
                }
            }
            let functionValue = getFunction(funcName: funcName, space: currentSpace)
            print(functionValue.params)
            print(localSpace)
            var paramsValid = true
            for i in 0...functionValue.params.count-1 {
                if functionValue.params[i].name != localSpace[i].name || functionValue.params[i].type != localSpace[i].type {
                    paramsValid = false
                }
            }
            if paramsValid {
                run(code: functionValue.code, space: localSpace)
            }
        }
    }
    //print(currentSpace)
}

var code = """
function do(a: Float, b: String) {
print(a*a);
print(b+b+"");
};
var o = "uiop";
var d = 8*(1+90);
do(a:d,b:"uiop");
"""
run(code: code, space: globalSpace)


