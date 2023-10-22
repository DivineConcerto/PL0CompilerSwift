import Foundation

indirect enum Node {
    case program(Node)
    case block([Node], [Node], [Node], Node)
    case procedure(String, Node)
    case constDeclaration(String, Int)
    case varDeclaration(String)
    case assignment(String, Node)
    case call(String)
    case compound([Node])
    case ifStatement(Node, Node, Node?)
    case whileStatement(Node, Node)
    case oddCondition(Node)
    case binaryCondition(String, Node, Node)
    case expression(Node, String?, Node?)
    case term(Node, String?, Node?)
    case factorNumber(Int)
    case factorIdentifier(String)
    case factorExpression(Node)
    case empty
}

// 该代码有几个问题：
// 1.处理块的时候有问题，前面的定义完全OK，但是当有块的时候就不行了。

struct Parser {
    private var tokens: [Token]
    private var position: Int

    init(tokens: [Token]) {
        self.tokens = tokens
        self.position = 0
    }

    mutating func parse() -> Node? {
        let programNode = program()
        if expect(type: .delimiter(".")) == nil {
            print("Error: Expected '.' at the end of the program.")
        }
        return programNode
    }

    mutating func program() -> Node {
        return .program(block())
    }

    mutating func block() -> Node {
        var constDeclarations = [Node]()
        var varDeclarations = [Node]()
        var procedures = [Node]()
        
        // 当前token地类型是声明
        while let token = peek(), token.isKeyword(["const", "var", "procedure"]) {
            switch token.type {
            case .keyword("const"):
                // 消耗掉const关键字
                consume()
                // 开始循环，直到遇到","为止
                repeat {
                    if let constNode = constDeclaration() {
                        // 声明一个常量后，将其语法树结点加入到数据中
                        constDeclarations.append(constNode)
                    }
                } while expect(type: .delimiter(",")) != nil
                
                if expect(type: .delimiter(";")) == nil {
                    print("Error: Expected ';' after const declarations.")
                }
                
            case .keyword("var"):
                consume()
                repeat {
                    if let varNode = varDeclaration() {
                        varDeclarations.append(varNode)
                    }
                } while expect(type: .delimiter(",")) != nil
                if expect(type: .delimiter(";")) == nil {
                    print("Error: Expected ';' after var declarations.")
                }
            case .keyword("procedure"):
                consume()
                if let procedureNode = procedure() {
                    procedures.append(procedureNode)
                }
            default:
                break
            }
        }

        return .block(constDeclarations, varDeclarations, procedures, statement())
    }

    mutating func constDeclaration() -> Node? {
        // 尝试获取一个标识符的token类型，如果存在并且成功获取到其到值，则进行以下操作
        // 这里有“”的错误，必须是空字符。
        if let identToken = expect(type: .ident("")), let ident = identToken.identifierValue() {
            // 如果获取到一个=
            if expect(type: .operatorToken("=")) != nil {
                // 如果还获取到一个数字，就证明是一个数字常量的声明
                if let numberToken = expect(type: .number(0)), let number = numberToken.numberValue() {
                    // 返回一个结点
                    return .constDeclaration(ident, number)
                } else {
                    print("Error: Expected number after '=' in const declaration.")
                }
            } else {
                print("Error: Expected '=' after identifier in const declaration.")
            }
        } else {
            print("Error: Expected identifier in const declaration.")
        }
        return nil
    }

    mutating func varDeclaration() -> Node? {
        // 这里也有错误
        if let identToken = expect(type: .ident("")), let ident = identToken.identifierValue() {
            return .varDeclaration(ident)
        } else {
            print("Error: Expected identifier in var declaration.")
            return nil
        }
    }

    mutating func procedure() -> Node? {
        // 同上
        if let identToken = expect(type: .ident("")), let ident = identToken.identifierValue() {
            if expect(type: .delimiter(";")) != nil {
                return .procedure(ident, block())
            } else {
                print("Error: Expected ';' after procedure declaration.")
            }
        } else {
            print("Error: Expected identifier in procedure declaration.")
        }
        return nil
    }

    mutating func statement() -> Node {
        if let token = peek() {
            switch token.type {
            case .ident(let ident):
                // 赋值语句
                consume()
                if expect(type: .operatorToken(":=")) != nil {
                    return .assignment(ident, expression())
                } else {
                    print("Error: Expected ':=' in assignment statement.")
                    return .empty
                }
            case .keyword("call"):
                // 调用语句
                consume()
                // 这里还有错误
                if let identToken = expect(type: .ident("")), let ident = identToken.identifierValue() {
                    return .call(ident)
                } else {
                    print("Error: Expected identifier after 'call'.")
                    return .empty
                }
            case .keyword("begin"):
                var statements = [Node]()
                // 循环，直到遇到;或者end 这里的问题在于，遇到一个;就直接退出了
                repeat {
                    consume()
                    statements.append(statement())
                } while expect(type: .delimiter(";")) != nil
                if expect(type: .keyword("end")) == nil {
                    print("Error: Expected 'end' to close 'begin'.")
                }
                return .compound(statements)
    
            case .keyword("if"):
                // 判断语句
                consume()
                let conditionNode = condition()
                // 解析then分支
                if expect(type: .keyword("then")) != nil {
                    let thenStatement = statement()
                    var elseStatement: Node? = nil
                    // 解析else分支
                    if expect(type: .keyword("else")) != nil {
                        elseStatement = statement()
                    }
                    return .ifStatement(conditionNode, thenStatement, elseStatement)
                } else {
                    print("Error: Expected 'then' after 'if' condition.")
                    return .empty
                }
            case .keyword("while"):
                // 循环语句
                consume()
                let conditionNode = condition()
                // 寻找do关键字
                if expect(type: .keyword("do")) != nil {
                    // 后面是一个语句
                    return .whileStatement(conditionNode, statement())
                } else {
                    print("Error: Expected 'do' after 'while' condition.")
                    return .empty
                }
            default:
                return .empty
            }
        } else {
            return .empty
        }
    }

    mutating func condition() -> Node {
        if expect(type: .keyword("odd")) != nil {
            return .oddCondition(expression())
        } else {
            let expr1 = expression()
            if let token = peek(), token.isOperator(["=", "<>", "<", "<=", ">", ">="]) {
                let opToken = consume()
                let expr2 = expression()
                if let op = opToken?.operatorValue() {
                    return .binaryCondition(op, expr1, expr2)
                }
            }
            print("Error: Invalid condition.")
            return .empty
        }
    }

    mutating func expression() -> Node {
        var op: String? = nil
        if let token = peek(), token.isOperator(["+", "-"]) {
            op = consume()?.operatorValue()
        }
        let termNode = term()
        var nextOp: String? = nil
        var nextTerm: Node? = nil
        if let token = peek(), token.isOperator(["+", "-"]) {
            nextOp = consume()?.operatorValue()
            nextTerm = term()
        }
        return .expression(termNode, op, nextTerm)
    }

    mutating func term() -> Node {
        let factorNode = factor()
        var op: String? = nil
        var nextFactor: Node? = nil
        if let token = peek(), token.isOperator(["*", "/"]) {
            op = consume()?.operatorValue()
            nextFactor = factor()
        }
        return .term(factorNode, op, nextFactor)
    }

    mutating func factor() -> Node {
        if let token = peek() {
            switch token.type {
            case .ident(let ident):
                consume()
                return .factorIdentifier(ident)
            case .number(let number):
                consume()
                return .factorNumber(number)
            case .delimiter("("):
                consume()
                let expr = expression()
                if expect(type: .delimiter(")")) == nil {
                    print("Error: Expected ')' to close '(' in factor.")
                }
                return .factorExpression(expr)
            default:
                print("Error: Invalid factor.")
                return .empty
            }
        } else {
            print("Error: Expected factor.")
            return .empty
        }
    }

    @discardableResult
    // 前进，返回返回当前token
    mutating func consume() -> Token? {
        guard position < tokens.count else { return nil }
        position += 1
        return tokens[position - 1]
    }
    
    // 查看当前Token
    mutating func peek() -> Token? {
        guard position < tokens.count else { return nil }
        return tokens[position]
    }
    
    // 检测当前的token是否与输入的类型相同，如果相同则返回当前token并前进一步，不同则返回nil
    mutating func expect(type: Token.TokenType) -> Token? {
        guard let token = peek(), token.type.matches(type: type) else {
            return nil
        }
        return consume()
    }
}

extension Token {
    func isKeyword(_ keywords: [String]) -> Bool {
        if case let .keyword(keyword) = self.type {
            return keywords.contains(keyword)
        }
        return false
    }

    func isOperator(_ operators: [String]) -> Bool {
        if case let .operatorToken(op) = self.type {
            return operators.contains(op)
        }
        return false
    }

    func identifierValue() -> String? {
        if case let .ident(value) = self.type {
            return value
        }
        return nil
    }

    func numberValue() -> Int? {
        if case let .number(value) = self.type {
            return value
        }
        return nil
    }

    func operatorValue() -> String? {
        if case let .operatorToken(value) = self.type {
            return value
        }
        return nil
    }
}

extension Token.TokenType {
    func matches(type: Token.TokenType) -> Bool {
        switch (self, type) {
        case (.ident, .ident): return true
        case (.number, .number): return true
        case (.operatorToken, .operatorToken): return true
        case (.delimiter, .delimiter): return true
        case (.keyword, .keyword): return true
        case (.unknown, .unknown): return true
        default: return false
        }
    }
}
