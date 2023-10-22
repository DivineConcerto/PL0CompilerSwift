import SwiftUI
struct CompilerView: View {
    @State private var sourceCode: String = ""
    @State private var lexicalTokens: [String] = []
    @State private var syntaxTree: String = ""
    @State private var semanticAnalysisOutput: String = ""
    @State private var pcodeOutput: String = ""
    
    var body: some View {
        VStack {
            Text("PL/0 Compiler").font(.headline)
            TextEditor(text: $sourceCode).border(Color.gray)
            Button("Analyze") {
                performCompilation()
            }
            Text("Lexical Analysis Output:")
            ScrollView {
                VStack(alignment: .leading) {
                    ForEach(lexicalTokens, id: \.self) { token in
                        Text(token)
                    }
                }
            }.border(Color.gray)
            Text("Syntax Analysis Output:")
            TextEditor(text: $syntaxTree).border(Color.gray)
            Text("Semantic Analysis Output:")
            TextEditor(text: $semanticAnalysisOutput).border(Color.gray)
            Text("P-Code Output:")
            TextEditor(text: $pcodeOutput).border(Color.gray)
        }.padding()
    }
    
    func performCompilation() {
        // Step 1: Perform Lexical Analysis
        var lexicalAnalyzer = LexicalAnalyzer(source: sourceCode)
        var tokens: [Token] = []
        var tokenResults: [String] = []
        while let token = lexicalAnalyzer.getNextToken() {
            tokens.append(token)
            switch token.type {
            case .ident(let value):
                tokenResults.append("Identifier: \(value)")
            case .number(let value):
                tokenResults.append("Number: \(value)")
            case .operatorToken(let value):
                tokenResults.append("OperatorToken: \(value)")
            case .keyword(let value):
                tokenResults.append("Keyword: \(value)")
            case .delimiter(let value):
                tokenResults.append("Delimiter: \(value)")
            case .unknown(let value):
                tokenResults.append("Unknown: \(value)")
            }
        }
        self.lexicalTokens = tokenResults
        
        // Step 2: Perform Syntax Analysis
        var parse = Parser(tokens: tokens)
        if var syntaxTree = parse.parse(){
            self.syntaxTree = "\(syntaxTree)"
        }
        
    }

}



#Preview {
    CompilerView()
}
