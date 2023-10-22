import Foundation

indirect enum ASTNode {
    // 声明
    case program([ASTNode])
    case block([ASTNode])
    case constDeclaration(String, Int)
    case varDeclaration(String)
    case procedureDeclaration(String, ASTNode)
    
    // 语句
    case assignStatement(String,ASTNode)
    case callStatement(String)
    case compoundStatement([ASTNode])
    case ifStatement(ASTNode,ASTNode,ASTNode?)
    case whileStatement(ASTNode,ASTNode)
    case readStatement(String)
    case writeStatement(String)

    // 条件
    case oddCondition(ASTNode)
    case binaryCondition(ASTNode,ConditionOperator,ASTNode)
    
    // 表达式
    case unaryExpression(ExpressionOperator,ASTNode)
    case binaryExpression(ASTNode,ExpressionOperator,ASTNode)
    case numberExpression(Int)
    case identifierExpression(String)
}

enum ConditionOperator{
    case equals,notEquals,lessThan,greaterThan,lessThanOrEquals,greaterThanOrEquals
}

enum ExpressionOperator{
    case add,subtract,multiply,divide
}

struct SyntaxAnalyzer {
    private let tokens: [Token]
    private var currentPosition: Int = 0

    init(tokens: [Token]) {
        self.tokens = tokens
    }

    mutating func parse() -> ASTNode? {
        return parseProgram()
    }

    // MARK: - 主程序解析
    mutating func parseProgram() -> ASTNode? {
        var nodes: [ASTNode] = []

        while !currentTokenMatches(.symbol(".")) && currentToken != nil {
            if let declaration = parseDeclaration() {
                nodes.append(declaration)
            } else if let statement = parseStatement() {
                nodes.append(statement)
                if !currentTokenMatches(.symbol(";")) {
                    break
                }
                advanceToken()  // 跳过 ';'
            } else if currentTokenMatches(.keyword("begin")) {
                if let block = parseBlock() {
                    nodes.append(block)
                }
            } else {
                advanceToken()  // Skip any unknown token
            }
        }

        return ASTNode.program(nodes)
    }

    
    private mutating func parseBlockOrStatement() -> ASTNode? {
        if currentTokenMatches(.keyword("begin")) {
            return parseCompoundStatement()
        } else {
            return parseDeclaration()
        }
    }



    private mutating func parseBlock() -> ASTNode? {
        var nodes: [ASTNode] = []

        // Parse declarations
        while currentTokenMatches(.keyword("const")) {
            if let constDecl = parseConstDeclaration() {
                nodes.append(constDecl)
            }
        }

        while currentTokenMatches(.keyword("var")) {
            if let varDecl = parseVarDeclaration() {
                nodes.append(varDecl)
            }
        }

        while currentTokenMatches(.keyword("procedure")) {
            if let procedureDecl = parseProcedureDeclaration() {
                nodes.append(procedureDecl)
            }
        }

        // Parse statements
        if currentTokenMatches(.keyword("begin")) {
            advanceToken()  // Skip 'begin'
            while !currentTokenMatches(.keyword("end")) && currentToken != nil {
                if let stmt = parseStatement() {
                    nodes.append(stmt)
                }
                if !currentTokenMatches(.symbol(";")) {
                    break
                }
                advanceToken()  // Skip ';'
            }
            if currentTokenMatches(.keyword("end")) {
                advanceToken()  // Skip 'end'
            }
        }

        return ASTNode.block(nodes)
    }




    



       

    // MARK: - 声明解析
    private mutating func parseDeclaration() -> ASTNode? {
        if currentTokenMatches(.keyword("const")) {
            return parseConstDeclaration()
        } else if currentTokenMatches(.keyword("var")) {
            return parseVarDeclaration()
        } else if currentTokenMatches(.keyword("procedure")) {
            return parseProcedureDeclaration()
        }
        return nil
    }

    private mutating func parseConstDeclaration() -> ASTNode? {
        advanceToken()
        if case .ident(let name) = currentToken?.type {
            advanceToken()
            if currentTokenMatches(.symbol("=")) {
                advanceToken()
                if case .number(let value) = currentToken?.type {
                    advanceToken()
                    if currentTokenMatches(.symbol(";")) {
                        advanceToken()
                        return ASTNode.constDeclaration(name, value)
                    }
                }
            }
        }
        return nil
    }

    private mutating func parseVarDeclaration() -> ASTNode? {
        advanceToken()
        if case .ident(let name) = currentToken?.type {
            advanceToken()
            return ASTNode.varDeclaration(name)
        }
        return nil
    }

   


    // MARK: - 语句解析
    private mutating func parseStatement() -> ASTNode? {
        if let token = currentToken {
            switch token.type {
            case .ident(_):
                return parseAssignmentStatement()
            case .keyword("call"):
                return parseCallStatement()
            case .keyword("begin"):
                return parseCompoundStatement()
            case .keyword("if"):
                return parseIfStatement()
            case .keyword("while"):
                return parseWhileStatement()
            case .keyword("read"):
                return parseReadStatement()
            case .keyword("write"):
                return parseWriteStatement()
            default:
                return nil
            }
        }
        return nil
    }

    private mutating func parseAssignmentStatement() -> ASTNode? {
        if case .ident(let name) = currentToken?.type {
            advanceToken()
            if currentTokenMatches(.symbol(":=")) {
                advanceToken()
                if let expression = parseExpression() {
                    return ASTNode.assignStatement(name, expression)
                }
            }
        }
        return nil
    }

    private mutating func parseCallStatement() -> ASTNode? {
        advanceToken()
        if case .ident(let name) = currentToken?.type {
            advanceToken()
            return ASTNode.callStatement(name)
        }
        return nil
    }

    private mutating func parseProcedureDeclaration() -> ASTNode? {
        if currentTokenMatches(.keyword("procedure")) {
            advanceToken()  // 跳过 'procedure'
            if case .ident(let name) = currentToken?.type {
                advanceToken()  // 跳过过程名称
                if currentTokenMatches(.symbol(";")) {
                    advanceToken()  // 跳过分号
                    if let block = parseBlock() {
                        if currentTokenMatches(.symbol(";")) {
                            advanceToken()  // 跳过分号
                            return ASTNode.procedureDeclaration(name, block)
                        }
                    }
                }
            }
        }
        return nil
    }
    private mutating func parseCompoundStatement() -> ASTNode? {
        advanceToken()
        var statements: [ASTNode] = []
        while !currentTokenMatches(.keyword("end")) && currentToken != nil {
            if let statement = parseStatement() {
                statements.append(statement)
            }
            if !currentTokenMatches(.symbol(";")) {
                break
            }
            advanceToken()
        }
        if currentTokenMatches(.keyword("end")) {
            advanceToken()
            return ASTNode.compoundStatement(statements)
        }
        return nil
    }



    private mutating func parseIfStatement() -> ASTNode? {
        advanceToken()
        if let condition = parseCondition() {
            if currentTokenMatches(.keyword("then")) {
                advanceToken()
                if let thenStatement = parseStatement() {
                    var elseStatement: ASTNode? = nil
                    if currentTokenMatches(.keyword("else")) {
                        advanceToken()
                        elseStatement = parseStatement()
                    }
                    return ASTNode.ifStatement(condition, thenStatement, elseStatement)
                }
            }
        }
        return nil
    }

    private mutating func parseWhileStatement() -> ASTNode? {
        advanceToken()
        if let condition = parseCondition() {
            if currentTokenMatches(.keyword("do")) {
                advanceToken()
                if let statement = parseStatement() {
                    return ASTNode.whileStatement(condition, statement)
                }
            }
        }
        return nil
    }
    
    private mutating func parseReadStatement() -> ASTNode? {
        advanceToken()
        if case .ident(let name) = currentToken?.type {
            advanceToken()
            return ASTNode.readStatement(name)
        }
        return nil
    }

    private mutating func parseWriteStatement() -> ASTNode? {
        advanceToken()
        if case .ident(let name) = currentToken?.type {
            advanceToken()
            return ASTNode.writeStatement(name)
        }
        return nil
    }

    // MARK: - 表达式解析
    private mutating func parseExpression() -> ASTNode? {
        var node = parseTerm()
        while let token = currentToken, token.isAdditionOperator || token.isSubtractionOperator {
            advanceToken()
            if let rightNode = parseTerm() {
                let op = token.isAdditionOperator ? ExpressionOperator.add : ExpressionOperator.subtract
                node = ASTNode.binaryExpression(node!, op, rightNode)
            } else {
                return nil
            }
        }
        return node
    }

    private mutating func parseTerm() -> ASTNode? {
        var node = parseFactor()
        while let token = currentToken, token.isMultiplicationOperator || token.isDivisionOperator {
            advanceToken()
            if let rightNode = parseFactor() {
                let op = token.isMultiplicationOperator ? ExpressionOperator.multiply : ExpressionOperator.divide
                node = ASTNode.binaryExpression(node!, op, rightNode)
            } else {
                return nil
            }
        }
        return node
    }

    private mutating func parseFactor() -> ASTNode? {
        if let token = currentToken {
            switch token.type {
            case .number(let value):
                advanceToken()
                return ASTNode.numberExpression(value)
            case .ident(let name):
                advanceToken()
                return ASTNode.identifierExpression(name)
            case .symbol("("):
                advanceToken()
                if let expr = parseExpression() {
                    if currentTokenMatches(.symbol(")")) {
                        advanceToken()
                        return expr
                    }
                }
            default:
                return nil
            }
        }
        return nil
    }

    // MARK: - 条件解析
    private mutating func parseCondition() -> ASTNode? {
        if currentTokenMatches(.keyword("odd")) {
            advanceToken()
            if let expression = parseExpression() {
                return ASTNode.oddCondition(expression)
            }
        } else {
            if let leftExpression = parseExpression() {
                if let conditionOperator = parseConditionOperator() {
                    if let rightExpression = parseExpression() {
                        return ASTNode.binaryCondition(leftExpression, conditionOperator, rightExpression)
                    }
                }
            }
        }
        return nil
    }

    private mutating func parseConditionOperator() -> ConditionOperator? {
        if let token = currentToken {
            switch token.type {
            case .symbol("="):
                advanceToken()
                return .equals
            case .symbol("<>"):
                advanceToken()
                return .notEquals
            case .symbol("<"):
                advanceToken()
                return .lessThan
            case .symbol("<="):
                advanceToken()
                return .lessThanOrEquals
            case .symbol(">"):
                advanceToken()
                return .greaterThan
            case .symbol(">="):
                advanceToken()
                return .greaterThanOrEquals
            default:
                return nil
            }
        }
        return nil
    }

    // MARK: - 辅助方法
    private var currentToken: Token? {
        if currentPosition < tokens.count {
            return tokens[currentPosition]
        }
        return nil
    }

    private mutating func advanceToken() {
        currentPosition += 1
    }

    private func currentTokenMatches(_ type: Token.TokenType) -> Bool {
        return currentToken?.type == type
    }
}

// MARK: - Token 扩展
extension Token.TokenType: Equatable {
    static func == (lhs: Token.TokenType, rhs: Token.TokenType) -> Bool {
        switch (lhs, rhs) {
        case (.ident(let lhsValue), .ident(let rhsValue)):
            return lhsValue == rhsValue
        case (.number(let lhsValue), .number(let rhsValue)):
            return lhsValue == rhsValue
        case (.symbol(let lhsValue), .symbol(let rhsValue)):
            return lhsValue == rhsValue
        case (.keyword(let lhsValue), .keyword(let rhsValue)):
            return lhsValue == rhsValue
        case (.unknown(let lhsValue), .unknown(let rhsValue)):
            return lhsValue == rhsValue
        default:
            return false
        }
    }
}

private extension Token {
    var isAdditionOperator: Bool {
        if case .symbol("+") = self.type { return true }
        return false
    }
    
    var isSubtractionOperator: Bool {
        if case .symbol("-") = self.type { return true }
        return false
    }
    
    var isMultiplicationOperator: Bool {
        if case .symbol("*") = self.type { return true }
        return false
    }
    
    var isDivisionOperator: Bool {
        if case .symbol("/") = self.type { return true }
        return false
    }
}
