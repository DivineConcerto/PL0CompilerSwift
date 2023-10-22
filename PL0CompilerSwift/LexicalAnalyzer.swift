import Foundation
struct Token {
    enum TokenType:Equatable {
        case ident(String)       // Identifier
        case number(Int)        // Number
        case operatorToken(String)  // Operator like +, -, etc.
        case delimiter(String)  // Delimiter like (, ), ;, etc.
        case keyword(String)    // Keyword like "begin", "end", etc.
        case unknown(String)    // Unknown type
    }
    
    let type: TokenType
}

struct LexicalAnalyzer {
    private let source: String
    private var position: String.Index
    private let symbols: Set<String> = ["+", "-", "*", "/", "(", ")", "=", ",", ".", ";", "<", ">", ":", ":="]
    private let keywords: Set<String> = ["begin", "end", "if", "then", "while", "do", "call", "const", "var", "procedure", "odd","read","write"]
    
    init(source: String) {
        self.source = source
        self.position = source.startIndex
    }
    
    mutating func getNextToken() -> Token? {
        // Skip whitespaces and newlines
        while position < source.endIndex, [" ", "\t", "\n", "\r"].contains(source[position]) {
            position = source.index(after: position)
        }
        
        // End of source
        if position == source.endIndex {
            return nil
        }
        
        let currentChar = String(source[position])
        
        // Check for symbols
        if currentChar == ":" && position < source.index(before: source.endIndex), source[source.index(after: position)] == "=" {
            position = source.index(after: position)  // Move over the "="
            position = source.index(after: position)  // Move to next token
            return Token(type: .operatorToken(":="))
        } else if symbols.contains(currentChar) {
            position = source.index(after: position)
            if [",", ".", ";", "(", ")"].contains(currentChar) {
                return Token(type: .delimiter(currentChar))
            } else {
                return Token(type: .operatorToken(currentChar))
            }
        }
        
        // Check for identifiers or keywords
        if Character(currentChar).isLetter {
            var identifier = currentChar
            position = source.index(after: position)
            while position < source.endIndex, source[position].isLetter || source[position].isNumber {
                identifier += String(source[position])
                position = source.index(after: position)
            }
            if keywords.contains(identifier) {
                return Token(type: .keyword(identifier))
            } else {
                return Token(type: .ident(identifier))
            }
        }
        
        // Check for numbers
        if Character(currentChar).isNumber {
            var number = currentChar
            position = source.index(after: position)
            while position < source.endIndex, source[position].isNumber {
                number += String(source[position])
                position = source.index(after: position)
            }
            return Token(type: .number(Int(number) ?? 0))
        }
        
        // Handle unknown token
        position = source.index(after: position)
        return Token(type: .unknown(currentChar))
    }
}
