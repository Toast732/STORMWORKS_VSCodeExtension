---@class LBSymbol
---@field type string
---@field raw string
LBSymbol = {
    new = function(this, type, raw, lineinfo)
        this = LifeBoatAPI.Tools.BaseClass.new(this)
        this.type = type
        this.raw = raw
        this.lineInfo = lineinfo
        return this
    end;

    fromToken = function(this, token)
        return LBSymbol:new(token.type, token.raw, token.lineInfo)
    end;
}

--- takes either a list of params, of a table in arg1
set = function(...)
    local args = {...}
    args = type(args[1]) == "table" and args[1] or args 

    local result = {}
    for i=1,#args do
        result[args[i]] = true
    end
    return result
end;



LBTokenTypes = {
    STRING          = "STRING",
    LBTAG           = "LBTAG",
    COMMENT         = "COMMENT",
    OPENBRACKET     = "OPENBRACKET",
    CLOSEBRACKET    = "CLOSEBRACKET",
    OPENSQUARE      = "OPENSQUARE",
    CLOSESQUARE     = "CLOSESQUARE",
    OPENCURLY       = "OPENCURLY",
    CLOSECURLY      = "CLOSECURLY",
    COMMA           = "COMMA",
    SEMICOLON       = "SEMICOLON",
    COMPARISON      = "COMPARISON",
    BINARY_OP       = "BINARY_OP",
    MIXED_OP        = "MIXED_OP",
    UNARY_OP        = "UNARY_OP",
    ASSIGN          = "ASSIGN",
    DOTACCESS       = "DOTACCESS",
    COLONACCESS     = "COLONACCESS",
    IDENTIFIER      = "IDENTIFIER",
    TYPECONSTANT    = "TYPECONSTANT",
    NUMBER          = "NUMBER",
    HEX             = "HEX",
    WHITESPACE      = "WHITESPACE",
    VARARGS         = "VARARGS",
    AND             = "AND",
    BREAK           = "BREAK",
    DO              = "DO",
    ELSE            = "ELSE",
    ELSEIF          = "ELSEIF",
    END             = "END",
    FOR             = "FOR",
    FUNCTION        = "FUNCTION",
    GOTO            = "GOTO",
    IF              = "IF",
    IN              = "IN",
    LOCAL           = "LOCAL",
    NOT             = "NOT",
    OR              = "OR",
    REPEAT          = "REPEAT",
    RETURN          = "RETURN",
    THEN            = "THEN",
    UNTIL           = "UNTIL",
    WHILE           = "WHILE",
    FALSE           = "FALSE",
    TRUE            = "TRUE",
    NIL             = "NIL",
    SOF = "SOF",
    EOF = "EOF"}

local T = LBTokenTypes



tokenizekeyword = function(keyword)
    if keyword == keyword:lower() then  -- ensure keyword is lowercase
        return LBTokenTypes[keyword:upper()]
    end
    return nil
end;

---@param text string
---@return LBToken[]
tokenize = function(text)
    local LBStr = LifeBoatAPI.Tools.StringUtils
    local tokens = {}
    local nextToken = ""

    local lineNumber = 1
    local lastLineStartIndex = 1

    --lex
    local iText = 1 
    while iText <= #text do
        local lineInfo = {
            line = lineNumber,
            index = iText,
            column = iText - lastLineStartIndex,
            toString = function(this)
                return string.format("line: %d, column: %d, index: %d", this.line, this.column, this.index)
            end
        }

        if LBStr.nextSectionIs(text, iText, '"') then
            -- quote (")
            iText, nextToken = LBStr.getTextIncluding(text, iText, '[^\\]"')
            tokens[#tokens+1] = LBSymbol:new(T.STRING, nextToken)

        elseif LBStr.nextSectionIs(text, iText, "'") then
            -- quote (')
            iText, nextToken = LBStr.getTextIncluding(text, iText, "[^\\]'")
            tokens[#tokens+1] = LBSymbol:new(T.STRING, nextToken)

        elseif LBStr.nextSectionIs(text, iText, "%[%[") then
            -- quote ([[ ]])
            iText, nextToken = LBStr.getTextIncluding(text, iText, "%]%]")
            tokens[#tokens+1] = LBSymbol:new(T.STRING, nextToken)  

        elseif LBStr.nextSectionIs(text, iText, "%-%-%-@lb") then
            -- preprocessor tag
            iText, nextToken = LBStr.getTextIncluding(text, iText, "%-%-%-@lb")
            tokens[#tokens+1] = LBSymbol:new(T.LBTAG, nextToken)

        elseif LBStr.nextSectionIs(text, iText, "%-%-%[%[") then
            -- multi-line comment
            iText, nextToken = LBStr.getTextIncluding(text, iText, "%]%]")
            tokens[#tokens+1] = LBSymbol:new(T.COMMENT, nextToken)

        elseif LBStr.nextSectionIs(text, iText, "%-%-") then
            -- single-line comment
            iText, nextToken = LBStr.getTextUntil(text, iText, "\n")
            tokens[#tokens+1] = LBSymbol:new(T.COMMENT, nextToken)

        elseif LBStr.nextSectionIs(text, iText, ";") then
            -- single-line comment
            iText, nextToken = iText+1, text:sub(iText, iText)
            tokens[#tokens+1] = LBSymbol:new(T.SEMICOLON, nextToken)

        elseif LBStr.nextSectionIs(text, iText, ",") then
            -- single-line comment
            iText, nextToken = iText+1, text:sub(iText, iText)
            tokens[#tokens+1] = LBSymbol:new(T.COMMA, nextToken)


        elseif LBStr.nextSectionIs(text, iText, "%(") then
            -- regular brackets
            iText, nextToken = iText+1, text:sub(iText, iText)
            tokens[#tokens+1] = LBSymbol:new(T.OPENBRACKET, nextToken)

        elseif LBStr.nextSectionIs(text, iText, "%[") then
            -- regular brackets
            iText, nextToken = iText+1, text:sub(iText, iText)
            tokens[#tokens+1] = LBSymbol:new(T.OPENSQUARE, nextToken)

        elseif LBStr.nextSectionIs(text, iText, "%{") then
            -- regular brackets
            iText, nextToken = iText+1, text:sub(iText, iText)
            tokens[#tokens+1] = LBSymbol:new(T.OPENCURLY, nextToken)


        elseif LBStr.nextSectionIs(text, iText, "%)") then
            -- regular brackets
            iText, nextToken = iText+1, text:sub(iText, iText)
            tokens[#tokens+1] = LBSymbol:new(T.CLOSEBRACKET, nextToken)

        elseif LBStr.nextSectionIs(text, iText, "%]") then
            -- regular brackets
            iText, nextToken = iText+1, text:sub(iText, iText)
            tokens[#tokens+1] = LBSymbol:new(T.CLOSESQUARE, nextToken)

        elseif LBStr.nextSectionIs(text, iText, "%}") then
            -- regular brackets
            iText, nextToken = iText+1, text:sub(iText, iText)
            tokens[#tokens+1] = LBSymbol:new(T.CLOSECURLY, nextToken)

        elseif LBStr.nextSectionIs(text, iText, ">>") then
            -- comparison
            iText, nextToken = iText+2, text:sub(iText, iText+1)
            tokens[#tokens+1] = LBSymbol:new(T.BINARY_OP, nextToken)

        elseif LBStr.nextSectionIs(text, iText, "<<") then
            -- comparison
            iText, nextToken = iText+2, text:sub(iText, iText+1)
            tokens[#tokens+1] = LBSymbol:new(T.BINARY_OP, nextToken)


        elseif LBStr.nextSectionIs(text, iText, "[><=~]=") then
            -- comparison
            iText, nextToken = iText+2, text:sub(iText, iText+1)
            tokens[#tokens+1] = LBSymbol:new(T.COMPARISON, nextToken)

        elseif LBStr.nextSectionIs(text, iText, "[><]") then
            -- comparison
            iText, nextToken = iText+1, text:sub(iText, iText)
            tokens[#tokens+1] = LBSymbol:new(T.COMPARISON, nextToken)

        elseif LBStr.nextSectionIs(text, iText, "//") then
            -- floor (one math op not two)
            iText, nextToken = iText+1, text:sub(iText, iText+1)
            tokens[#tokens+1] = LBSymbol:new(T.BINARY_OP, nextToken)

        elseif LBStr.nextSectionIs(text, iText, "#") then
            -- all other math ops
            iText, nextToken = iText+1, text:sub(iText, iText)
            tokens[#tokens+1] = LBSymbol:new(T.UNARY_OP, nextToken)
        
        elseif LBStr.nextSectionIs(text, iText, "~%-") then
            -- all other math ops
            iText, nextToken = iText+1, text:sub(iText, iText)
            tokens[#tokens+1] = LBSymbol:new(T.MIXED_OP, nextToken)

        elseif LBStr.nextSectionIs(text, iText, "[%*/%+%%%^&|]") then
            -- all other math ops
            iText, nextToken = iText+1, text:sub(iText, iText)
            tokens[#tokens+1] = LBSymbol:new(T.BINARY_OP, nextToken)


        elseif LBStr.nextSectionIs(text, iText, "%.%.%.") then
            -- varargs
            iText, nextToken = iText+3, text:sub(iText, iText+2)
            tokens[#tokens+1] = LBSymbol:new(T.VARARGS, nextToken)

        elseif LBStr.nextSectionIs(text, iText, "%.%.") then
            -- concat
            iText, nextToken = iText+2, text:sub(iText, iText+1)
            tokens[#tokens+1] = LBSymbol:new(T.BINARY_OP, nextToken)



        elseif LBStr.nextSectionIs(text, iText, "=") then
            -- assignment
            iText, nextToken = iText+1, text:sub(iText, iText)
            tokens[#tokens+1] = LBSymbol:new(T.ASSIGN, nextToken)

        elseif LBStr.nextSectionIs(text, iText, "[%a_][%w_]*") then
            -- keywords & identifier
            iText, nextToken = LBStr.getTextIncluding(text, iText, "[%a_][%w_]*")
            local keyword = tokenizekeyword(nextToken)
            if keyword then
                tokens[#tokens+1] = LBSymbol:new(keyword, nextToken)
            else
                tokens[#tokens+1] = LBSymbol:new(T.IDENTIFIER, nextToken)
            end

        elseif LBStr.nextSectionIs(text, iText, "%s+") then
            -- whitespace
            local startIndex = iText
            iText, nextToken = LBStr.getTextIncluding(text, iText, "%s*")
            tokens[#tokens+1] = LBSymbol:new(T.WHITESPACE, nextToken)
            -- update line info
            local newLines = LBStr.find(nextToken, "\n")
            if #newLines > 0 then
                lineNumber = lineNumber + #newLines
                lastLineStartIndex = startIndex + newLines[#newLines].endIndex
            end


        elseif LBStr.nextSectionIs(text, iText, "0x%x+") then
            -- hex 
            iText, nextToken = LBStr.getTextIncluding(text, iText, "0x%x+")
            tokens[#tokens+1] = LBSymbol:new(T.HEX, nextToken)

        elseif LBStr.nextSectionIs(text, iText, "%d*%.?%d+") then 
            -- number
            iText, nextToken = LBStr.getTextIncluding(text, iText, "%d*%.?%d+")
            tokens[#tokens+1] = LBSymbol:new(T.NUMBER, nextToken)

        elseif LBStr.nextSectionIs(text, iText, "%.") then
            -- chain access
            iText, nextToken = iText+1, text:sub(iText, iText)
            tokens[#tokens+1] = LBSymbol:new(T.DOTACCESS, nextToken)

        elseif LBStr.nextSectionIs(text, iText, "%:") then
            -- chain access
            iText, nextToken = iText+1, text:sub(iText, iText)
            tokens[#tokens+1] = LBSymbol:new(T.COLONACCESS, nextToken)

        else
            error(lineInfo:toString() .. "\nCan't process symbol \"" .. text:sub(iText, iText+10) .. "...\"\n\n\"" .. text:sub(math.max(0, iText-20), iText+20) .. "...\"")
        end
        tokens[#tokens].lineInfo = lineInfo
    end

    -- insert StartOfFile and EndOfFile tokens for whitespace association
    --  need to find first non-whitespace/non-comment node
    local i = 1
    while i <= #tokens do
        if not is(tokens[i].type, T.WHITESPACE, T.COMMENT) then
            break;
        end
        i=i+1
    end
    -- add the EOF marker
    tokens[#tokens+1] = LBSymbol:new(T.EOF)

    return associateRightWhitespaceAndComments(tokens)
end;

associateRightWhitespaceAndComments = function(tokens)
    local result = {}
    local leadingWhitespace = {}
    for itokens=1, #tokens do
        if is(tokens[itokens].type, T.WHITESPACE, T.COMMENT) then
            leadingWhitespace[#leadingWhitespace+1] = tokens[itokens]
        else
            local token = tokens[itokens]
            result[#result+1] = token
            for ileadingWhitespace=1, #leadingWhitespace do
                token[#token+1] = leadingWhitespace[ileadingWhitespace]
            end
            leadingWhitespace = {}
        end
    end

    -- add any trailing whitespace to the EOF marker
    local eofToken = tokens[#tokens]
    if #leadingWhitespace > 0 then
        for ileadingWhitespace=1, #leadingWhitespace do
            eofToken[#eofToken+1] = leadingWhitespace[ileadingWhitespace]
        end
    end
    return result
end;

insertIntoTable = function(tbl, list)
    for i=1,#list do
        tbl[#tbl+1] = list[i]
    end

    return tbl
end;




is = function(obj, ...)
    local args = {...}
    for i=1,#args do
        if obj == args[i] then
            return args[i]
        end
    end
    return nil
end;



-- what things can we do from "regular scope"

---@class Parse
---@field parent Parse
---@field tokens LBSymbol[]
---@field symbol LBSymbol
---@field i number
---@field isFunctionScope boolean only affects one thing "is return a valid keyword"
---@field errorObj any
Parse = {
    ---@return Parse
    new = function(this, type, tokens, i, parent)
        this = LifeBoatAPI.Tools.BaseClass.new(this)
        this.i = i or 1
        this.tokens = tokens
        this.symbol = LBSymbol:new(type)
        this.parent = parent
        this.isFunctionScope = parent and parent.isFunctionScope or false
        return this
    end;

    ---@return Parse
    branch = function(this, type)
        return Parse:new(type, this.tokens, this.i, this)
    end;

    ---@param this Parse
    commit = function(this)
        if this.parent then
            this.parent.symbol[#this.parent.symbol+1] = this.symbol
            this.parent.i = this.i
        end
        return true
    end;

    error = function(this, message)
        local lineInfo = this.tokens[this.i].lineInfo
        if (not this.errorObj) or (lineInfo.index > this.errorObj.index) then
            this.errorObj = {
                owner = this,
                message = message,
                i = this.i,
                index = lineInfo.index,
                line = lineInfo.line,
                column = lineInfo.column,
                toString = function(err)
                    return "line: " .. err.line .. ", column: " .. err.column .. ", index: " .. err.index .. "\n"
                        .. "at token " .. err.i .. ": " .. this.tokens[err.i].raw .. "\n"
                        .. message .. "\n"
                end;
            }
        end

        if (not this.parent.errorObj) or (this.errorObj.index > this.parent.errorObj.index) then
            this.parent.errorObj = this.errorObj
        end
        return false
    end;

    ---@return boolean
    match = function(this, ...)
        return is(this.tokens[this.i].type, ...)
    end;

    ---@return boolean
    consume = function(this, ...)
        local consumedAny = this:tryConsume(...)
        while(this:tryConsume(...)) do end
        return consumedAny
    end;

    ---@return boolean
    tryConsume = function(this, ...)
        if is(this.tokens[this.i].type, ...) then
            this.symbol[#this.symbol+1] = this.tokens[this.i]
            this.i = this.i + 1
            return true
        else
            return false
        end
    end;

    ---@param this Parse
    tryConsumeRules = function(this, ...)
        local rules = {...}
        for irules=1, #rules do
            local rule = rules[irules]
            if rule(this) then
                return true
            end
        end
        return false
    end;

    ---@param this Parse
    tryConsumeRulesAs = function(this, name, ...)
        local branch = this:branch(name)
        local result = branch:tryConsumeRules(...)
        if result then
            branch:commit()
        else
            branch:error("Failed to parse as " .. tostring(name))
        end
        return result
    end;
}


LBSymbolTypes = {
    FUNCTIONDEF         = "FUNCTIONDEF",
    FUNCTIONCALL        = "FUNCTIONCALL",
    TABLEDEF            = "TABLEDEF",
    WHILE_LOOP          = "WHILE_LOOP",
    FOR_LOOP            = "FOR_LOOP",
    DO_END              = "DO_END",
    REPEAT_UNTIL        = "REPEAT_UNTIL",
    SQUARE_BRACKETS     = "SQUARE_BRACKETS",
    
    IF_STATEMENT        = "IF_STATEMENT",
    IF_CONDITION        = "IF_CONDITION",

    BODY                = "BODY",

    ASSIGNMENT          = "ASSIGNMENT",
    PROGRAM             = "PROGRAM",
    PARENTHESIS         = "PARENTHESIS",
    EXPCHAIN            = "EXPCHAIN",
    OPERATORCHAIN       = "OPERATORCHAIN",
    DECLARE_LOCAL       = "DECLARE_LOCAL",
    FUNCTIONDEF_PARAMS  = "FUNCTIONDEF_PARAMS",
    PARAM               = "PARAM"
    }
local S = LBSymbolTypes


---@param parse Parse
Statement = function(parse)
    parse = parse:branch(S.STATEMENT)
    if parse:tryConsumeRules(
        NamedFunctionDefinition,
        AssignmentOrLocalDeclaration,
        FunctionCallStatement,
        IfStatement,

        -- other statements

        ProcessorLBTagSection,
        parse.isFunctionScope and ReturnStatement or nil
    ) then
        return parse:commit()
    end

    return parse:error("Invalid statement")
end;


SquareBracketsIndex = function(parse)
    parse = parse:branch(S.SQUARE_BRACKETS)

    if parse:tryConsume(T.OPENSQUARE)
        and parse:tryConsumeRules(Expression)
        and parse:tryConsume(T.CLOSESQUARE) then

        return parse:commit()
    end

    return parse:error("Invalid square-bracket index")
end

ParenthesisExpression = function(parse)
    parse = parse:branch(S.PARENTHESIS)

    if parse:tryConsume(T.OPENBRACKET)
        and parse:tryConsumeRules(Expression)
        and parse:tryConsume(T.CLOSEBRACKET) then

        return parse:commit()
    end

    return parse:error("Invalid parenthesis expression")
end;

TableDef = function(parse)
    parse = parse:branch(S.TABLEDEF)

    if parse:tryConsume(T.OPENCURLY) then
        
        if parse:tryConsumeRules(TableValueInitialization) then
            while parse:tryConsume(T.COMMA, T.SEMICOLON) do
                if not parse:tryConsumeRules(TableValueInitialization) then
                    break; -- it's valid to end on a comma/semi-colon
                end
            end
        end

        
        if parse:tryConsume(T.CLOSECURLY) then
            return parse:commit()
        end
    end

    return parse:error("Invalid table definition")
end;

---@param parse Parse
FunctionDefParenthesis = function(parse)
    parse = parse:branch(S.FUNCTIONDEF_PARAMS)
    if parse:tryConsume(T.OPENBRACKET) then

        if(parse:tryConsume(T.IDENTIFIER)) then
            
            while(parse:tryConsume(T.COMMA)) do
                if parse:tryConsume(T.VARARGS) then
                    break -- should be final parameter, so close brackets next
                end
                if not parse:tryConsume(T.IDENTIFIER) then
                    return parse:error("Expected parameter after ','")
                end
            end
        end

        if parse:tryConsume(T.CLOSEBRACKET) then
            return parse:commit()
        end
    end

    return parse:error("Invalid function-definition parenthesis")
end;

ExpressionList = function(parse)
    -- a,b,c,d,e comma separated items
    parse = parse:branch()
    if parse:tryConsumeRules(Expression) then
        while parse:tryConsume(T.COMMA) do
            if not parse:tryConsumeRules(Expression) then
                return parse:error("Expression list must not leave trailing ','")
            end
        end

        return parse:commit()
    end

    return parse:error("Invalid expression-list")
end;

---@param parse Parse
ReturnStatement = function(parse)
    parse = parse:branch()
    if parse:tryConsume(T.RETURN)
        and parse:tryConsumeRules(ExpressionList) then
        return parse:commit() 
    end

    return parse:error("Invalid return statement")
end

---@param parse Parse
AnonymousFunctionDef = function(parse)
    parse = parse:branch(S.FUNCTIONDEF)

    if parse:tryConsume(T.FUNCTION) 
    and parse:tryConsumeRules(FunctionDefParenthesis) then

        parse.isFunctionScope = true;
        parse:tryConsumeRules(genBody(T.END))

        if parse:tryConsume(T.END) then
            return parse:commit()
        end
    end

    return parse:error("Invalid anonymous function definition")
end;

---@param parse Parse
NamedFunctionDefinition = function(parse, ...)
    parse = parse:branch(S.FUNCTIONDEF)

    if parse:tryConsume(T.FUNCTION)
        and parse:tryConsume(T.IDENTIFIER) then

        -- for each ".", require a <name> after
        while parse:tryConsume(T.DOTACCESS) do
            if not parse:tryConsume(T.IDENTIFIER) then
                return parse:error("Expected identifier after '.' ")
            end
        end

        -- if : exists, require <name> after
        if parse:tryConsume(T.COLONACCESS) then
            if not parse:tryConsume(T.IDENTIFIER) then
                return parse:error("Expected final identifier after ':' ")
            end
        end

        if parse:tryConsumeRules(FunctionDefParenthesis) then

            parse.isFunctionScope = true;
            parse:tryConsumeRules(genBody(T.END))

            if parse:tryConsume(T.END) then
                return parse:commit()
            end
        end
    end

    return parse:error("Invalid named-function definition")
end;

---@param parse Parse
BinaryExpression = function(parse)
    parse = parse:branch(S.OPERATORCHAIN)
    if parse:tryConsumeRules(SingleExpression)
        and parse:tryConsume(T.AND, T.OR, T.MIXED_OP, T.BINARY_OP, T.COMPARISON)
        and parse:tryConsumeRules(Expression) then

        return parse:commit()
    end

    return parse:error("Invalid binary expression")
end;


LValue = function(parse)
    parse = parse:branch() -- no typename; meaning it will simplify out

    -- messy but easier way to handle Lvalues: (saves a lot of duplication)
    -- easiest thing to do is, check if we can make a valid ExpChain and then make sure the end of it is actually modifiable
    if parse:tryConsume(ExpressionChainedOperator)
        and parse.symbol[#parse.symbol] and parse.symbol[#parse.symbol][#parse.symbol[#parse.symbol]]
        and is(parse.symbol[#parse.symbol][#parse.symbol[#parse.symbol]].type, S.SQUARE_BRACKETS, T.IDENTIFIER) then
            parse.symbol.type = S.LVALUE
            return parse:commit()
    end

    return parse:error("Invalid lvalue")
end;



---@param parse Parse
FunctionCallStatement = function(parse)
    parse = parse:branch()

    -- save a lot of duplication by finding a valid ExpChain and then backtracking
    if parse:tryConsume(ExpressionChainedOperator)
        and parse.symbol[#parse.symbol] and parse.symbol[#parse.symbol[#parse.symbol]]
        and is(parse.symbol[#parse.symbol][#parse.symbol[#parse.symbol]].type, S.FUNCTIONCALL) then
            parse.symbol = S.FUNCTIONCALL
            return parse:commit()
    end

    return parse:error("Invalid function call statement")
end;


---@param parse Parse
ExpressionChainedOperator = function(parse)
    -- a = (1+2)()()[1].123 param,func,func,accesschain,accesschain
    -- singleExpressions can chain into infinite function calls, etc.
    parse = parse:branch(S.EXPCHAIN)
    if parse:tryConsume(T.IDENTIFIER) or parse:tryConsumeRules(ParenthesisExpression) then
        while true do
            if parse:tryConsume(T.DOTACCESS) then -- .<name>
                if not parse:tryConsume(T.IDENTIFIER) then
                    return parse:error("Expected identifier after '.' ")
                end
            elseif parse:tryConsume(T.COLONACCESS) then -- :<name>(func) 
                if not (parse:tryConsume(T.IDENTIFIER)
                       and parse:tryConsumeRules(FunctionCallParenthesis)) then
                    return parse:error("Expected function call after ':'")
                end
            elseif parse:tryConsumeRules(SquareBracketsIndex, FunctionCallParenthesis) then -- [123] or (a,b,c)
                -- all OK
            else
                return parse:commit();
            end
        end
    end

    return parse:error("Invalid expression chain")
end

SingleExpression = function(parse)
    -- single expression, not lined by binary, e.g. a string, an identifier-chain, etc.
    parse = parse:branch()

    -- clear any unary operators from the front
    while parse:tryConsume(T.UNARY_OP, T.MIXED_OP) do end

    if parse:tryConsumeRules(
        ParenthesisExpression,
        ExpressionChainedOperator, -- (exp.index.index.index[index][index](func)(func)(func))
        TableDef,
        AnonymousFunctionDef) 
        or parse:tryConsume(T.STRING, T.NUMBER, T.HEX, T.TRUE, T.FALSE, T.NIL)  -- hard-coded value
        then
        return parse:commit()
    end

    return parse:error("Invalid single-expression")
end;

---@param parse Parse
Expression = function(parse)
    -- identifier.access
    -- expression mathop|concat expression chain
    -- parenthesis -> expression
    parse = parse:branch()

    if parse:tryConsumeRules(
        BinaryExpression, -- (exp op exp) (infinite chain-> single_exp op (exp op exp)) etc.
        SingleExpression
    ) then
        return parse:commit()
    end

    return parse:error("Invalid expression")
end;

genBody = function(...)
    local args = {...}

    ---@param parse Parse
    return function(parse)
        parse = parse:branch(S.BODY)

        while not parse:match(table.unpack(args)) do
            if not parse:tryConsumeRules(Statement) then
                return parse:error("Failed to terminate body")
            end
        end

        return parse:commit()
    end;
end

---@param parse Parse
IfStatement = function(parse)
    parse = parse:branch(S.IF_STATEMENT)
    if parse:tryConsume(T.IF) 
        and parse:tryConsumeRulesAs(S.IF_CONDITION, Expression)
        and parse:tryConsume(T.THEN) then
        
        -- statements, if any - may be empty
        parse:tryConsumeRules(genBody(T.ELSEIF, T.ELSE, T.END))

        -- potential for elseifs (if they exist, must be well structured or return false "badly made thingmy")
        while parse:tryConsume(T.ELSEIF) do
            if not (parse:tryConsumeRulesAs(S.IF_CONDITION, Expression)
                and parse:tryConsume(T.THEN)) then
                return parse:error("Improperly specified elseif statement")
            else
                -- parse statements in the "elseif" section
                parse:tryConsumeRules(genBody(T.ELSEIF, T.ELSE, T.END))
            end
        end

        -- possible "else" section
        if parse:tryConsume(T.ELSE) then
            parse:tryConsumeRules(genBody(T.END))
        end

        if parse:tryConsume(T.END) then
            return parse:commit()
        end
    end

    return parse:error("Invalid if Statement")
end;

---@param parse Parse
AssignmentOrLocalDeclaration = function(parse)
    parse = parse:branch(S.ASSIGNMENT)
    local isLocal = parse:tryConsume(T.LOCAL)
    
    if parse:tryConsumeRules(LValue) then -- check last part of the EXPCHAIN was assignable
        
        -- now check repeatedly for the same, with comma separators
        --   return false if a comma is provided, but not a valid assignable value
        while parse:tryConsume(T.COMMA) do
            if not parse:tryConsumeRules(LValue) then
                return parse:error("Expected lvalue after comma")
            end
        end

        if parse:tryConsume(T.ASSIGN) then -- equals sign "="
            -- expect a list of expressions to assign
            if parse:tryConsumeRules(ExpressionList) then
                return parse:commit()
            end
        elseif isLocal then
            -- if declared local, can be a simple "local statement" with no value - as rare as that is
            parse.symbol.type = S.DECLARE_LOCAL
            return parse:commit()
        end
    end

    return parse:error("Invalid Assignment/Local Declaration")
end;

---@param parse Parse
FunctionCallParenthesis = function(parse)
    parse = parse:branch()
    if  parse:tryConsume(T.OPENBRACKET) then

        -- can be empty parens
        parse:tryConsumeRules(ExpressionList)

        if parse:tryConsume(T.CLOSEBRACKET) then
            return parse:commit()
        end
    end

    return parse:error("Invalid function call parenthesis")
end;

TableAssignment = function(parse)
    parse = parse:branch(S.ASSIGNMENT)
    local isLocal = parse:tryConsume(T.LOCAL)
    
    if parse:tryConsumeRules(SquareBracketsIndex)
        or parse:tryConsume(T.IDENTIFIER) then

        if parse:tryConsume(T.ASSIGN) 
            and parse:tryConsumeRules(Expression) then

            return parse:commit()
        end
    end

    return parse:error("Invalid table assignment")
end;

TableValueInitialization = function(parse)
    parse = parse:branch()
    if parse:tryConsumeRules(
        Expression,
        TableAssignment
    ) then
        return parse:commit()
    end

    return parse:error("Invalid table value")
end;

ProcessorLBTagSection = function(parse)
end;

ForLoopStatement = function(parse)
end;


WhileLoopStatement = function(parse)
end;

RepeatUntilStatement = function(parse)
end;

DoEndStatement = function(parse)
end;

-- could arguably ban this
GotoStatement = function(parse)
end;


Program = function(parse)
    local parse = parse:branch()

    parse:tryConsumeRules(genBody(T.EOF))

    if parse:tryConsume(T.EOF) then
        return parse:commit()
    end

    return parse:error("Did not reach EOF")
end;


---@return string
toStringTokens = function(tokens)
    local result = {}
    for i=1,#tokens do
        result[#result+1] = tokens[i].raw
    end
    return table.concat(result)
end;

toStringParse = function(tree)
    local result = {}
    for i=1,#tree do
        result[#result+1] = toStringParse(tree[i])
        result[#result+1] = tree[i].raw
    end
    return table.concat(result)
end;

---@param tree LBSymbol
simplify = function(tree)
    local i = 1   
    while i <= #tree do
        local child = tree[i]

        if not child.type or (tree.type == child.type) then
            
            if child[1] then
                tree[i] = child[1]
            end
            for ichild=2, #child do
                table.insert(tree, i+ichild-1, child[ichild])
            end
        else
            simplify(tree[i])
            i = i + 1
        end 
    end

    return tree
end;

parse = function(text)
    local tokens = tokenize(text)
    local parser = Parse:new(nil, tokens, 1)
    local result = Program(parser)

    if not result then
        error(parser.errorObj:toString())
    end
    
    return simplify(parser.symbol)
end;

testParse = function(parseFunc, text)
    local tokens = tokenize(text)
    local parser = Parse:new("TEST", tokens, 1)
    local result = parseFunc(parser)
    
    return simplify(parser.symbol)
end;


local text = LifeBoatAPI.Tools.FileSystemUtils.readAllText(LifeBoatAPI.Tools.Filepath:new([[C:\personal\STORMWORKS_VSCodeExtension\parsing_learning\MyMicrocontroller.lua]]))

local parsed = parse(text)

LifeBoatAPI.Tools.FileSystemUtils.writeAllText(
    LifeBoatAPI.Tools.Filepath:new([[C:\personal\STORMWORKS_VSCodeExtension\parsing_learning\gen1.lua]]),
    toStringParse(parsed))


__simulator:exit()
