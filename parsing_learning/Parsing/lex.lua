
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

is = function(obj, ...)
    local args = {...}
    for i=1,#args do
        if obj == args[i] then
            return args[i]
        end
    end
    return nil
end;



---@class LBSymbol
---@field type string
---@field raw string
LBSymbol = {
    new = function(this, type, raw, lineinfo)
        return {
            type = type,
            raw = raw,
            lineInfo = lineinfo
        }
    end;

    fromToken = function(this, token)
        return LBSymbol:new(token.type, token.raw, token.lineInfo)
    end;
}


LBTokenTypes = {
    STRING          = "STRING",
    LBTAG_START     = "LBTAG_START",
    LBTAG_END       = "LBTAG_END",
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
    GOTOMARKER      = "GOTO_LABEL",
    EOF             = "EOF"}

local T = LBTokenTypes


local LBKeywords = {
    ["and"]             = LBTokenTypes.AND,
    ["break"]           = LBTokenTypes.BREAK,
    ["do"]              = LBTokenTypes.DO,
    ["else"]            = LBTokenTypes.ELSE,
    ["elseif"]          = LBTokenTypes.ELSEIF,
    ["end"]             = LBTokenTypes.END,
    ["for"]             = LBTokenTypes.FOR,
    ["function"]        = LBTokenTypes.FUNCTION,
    ["goto"]            = LBTokenTypes.GOTO,
    ["if"]              = LBTokenTypes.IF,
    ["in"]              = LBTokenTypes.IN,
    ["local"]           = LBTokenTypes.LOCAL,
    ["not"]             = LBTokenTypes.NOT,
    ["or"]              = LBTokenTypes.OR,
    ["repeat"]          = LBTokenTypes.REPEAT,
    ["return"]          = LBTokenTypes.RETURN,
    ["then"]            = LBTokenTypes.THEN,
    ["until"]           = LBTokenTypes.UNTIL,
    ["while"]           = LBTokenTypes.WHILE,
    ["false"]           = LBTokenTypes.FALSE,
    ["true"]            = LBTokenTypes.TRUE,
    ["nil"]             = LBTokenTypes.NIL,
}

local tokenizekeyword = function(keyword)
    return LBKeywords[keyword]
end;

local getString = function(lineInfo, text, iText, ending)
    local start = iText
    iText = iText + 1
    while iText <= #text do
        local char = text:sub(iText,iText)
        if char == "\\" then
            iText = iText + 2
        elseif char == ending then
            return iText+1, text:sub(start, iText)
        else
            iText = iText + 1
        end
    end

    error(lineInfo:toString() .. "\nIncomplete string, starting at: " .. iText .. ": \n " .. text:sub(start) )
end;

local associateRightWhitespaceAndComments = function(tokens)
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

---@param text string
---@return LBToken[]
tokenize = function(text)
    local LBStr = LifeBoatAPI.Tools.StringUtils
    local nextSectionEquals = LBStr.nextSectionEquals
    local nextSectionIs = LBStr.nextSectionIs

    --performance lookups
    local lookup_digit = set("1","2","3","4","5","6","7","8","9","0",".")
    local lookup_alpha = set("_", "a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z",
                                  "A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z")
    local lookup_math  = set("*","/","+","%","^","&","|")
    local lookup_ws    = set(" ", "\n", "\r", "\t")



    local tokens = {}
    local nextToken = ""

    local lineNumber = 1
    local lastLineStartIndex = 1
    local iText = 1

    local getLineInfo = function()
        return {
            line = lineNumber,
            index = iText,
            column = 1 + iText - lastLineStartIndex,
            toString = function(this)
                return string.format("line: %d, column: %d, index: %d", this.line, this.column, this.index)
            end
        };
    end;

    while iText <= #text do
        local lineInfo = getLineInfo()
        local startIndex = iText
        local nextChar = text:sub(iText,iText)
        local next2Char = text:sub(iText,iText+1)
        
        if nextChar == '"' then
            -- quote (")
            iText, nextToken = getString(lineInfo, text, iText, '"')
            tokens[#tokens+1] = LBSymbol:new(T.STRING, nextToken)

        elseif nextChar == "'" then
            -- quote (')
            iText, nextToken = getString(lineInfo, text, iText, "'")
            tokens[#tokens+1] = LBSymbol:new(T.STRING, nextToken)

        elseif (next2Char == "[[" or next2Char == "[=") and nextSectionIs(text, iText, "%[=-%[") then
            -- quote ([[ ]])
            -- annoying syntax thing they added [====[ comment ]====] with same number of equals on either side
            local numEquals = 0
            local closingPattern = {"%]"}
            while text:sub(iText+3+numEquals,iText+3+numEquals) == '=' do
                numEquals = numEquals + 1
                closingPattern[#closingPattern+1] = "="
            end
            closingPattern[#closingPattern+1] = "%]"
            iText, nextToken = LBStr.getTextIncluding(text, iText, table.concat(closingPattern))
            tokens[#tokens+1] = LBSymbol:new(T.STRING, nextToken)  

        elseif nextSectionEquals(text, iText, "---@lb(end)") then
            -- preprocessor tag
            iText, nextToken = iText+11, text:sub(iText, iText+10)
            tokens[#tokens+1] = LBSymbol:new(T.LBTAG_END, nextToken)

        elseif nextSectionEquals(text, iText, "---@lb") then
            -- preprocessor tag
            iText, nextToken = iText+6, text:sub(iText, iText+5)
            tokens[#tokens+1] = LBSymbol:new(T.LBTAG_START, nextToken)

        elseif nextSectionEquals(text, iText, "--[") and nextSectionIs(text, iText, "%-%-%[=-%[") then
            -- multi-line comment
            -- annoying syntax thing they added [====[ comment ]====] with same number of equals on either side
            local numEquals = 0
            local closingPattern = {"%]"}
            while text:sub(iText+3+numEquals,iText+3+numEquals) == '=' do
                numEquals = numEquals + 1
                closingPattern[#closingPattern+1] = "="
            end
            closingPattern[#closingPattern+1] = "%]"

            iText, nextToken = LBStr.getTextIncluding(text, iText, table.concat(closingPattern))
            tokens[#tokens+1] = LBSymbol:new(T.COMMENT, nextToken)

        elseif next2Char == "--" then
            -- single-line comment
            iText, nextToken = LBStr.getTextUntil(text, iText, "\n")
            tokens[#tokens+1] = LBSymbol:new(T.COMMENT, nextToken)

        elseif nextChar == ";" then
            -- single-line comment
            iText, nextToken = iText+1, nextChar
            tokens[#tokens+1] = LBSymbol:new(T.SEMICOLON, nextToken)

        elseif nextChar == "," then
            -- single-line comment
            iText, nextToken = iText+1, nextChar
            tokens[#tokens+1] = LBSymbol:new(T.COMMA, nextToken)


        elseif nextChar == "(" then
            -- regular brackets
            iText, nextToken = iText+1, nextChar
            tokens[#tokens+1] = LBSymbol:new(T.OPENBRACKET, nextToken)

        elseif nextChar == "[" then
            -- regular brackets
            iText, nextToken = iText+1, nextChar
            tokens[#tokens+1] = LBSymbol:new(T.OPENSQUARE, nextToken)

        elseif nextChar == "{" then
            -- regular brackets
            iText, nextToken = iText+1, nextChar
            tokens[#tokens+1] = LBSymbol:new(T.OPENCURLY, nextToken)


        elseif nextChar == ")" then
            -- regular brackets
            iText, nextToken = iText+1, nextChar
            tokens[#tokens+1] = LBSymbol:new(T.CLOSEBRACKET, nextToken)

        elseif nextChar == "]" then
            -- regular brackets
            iText, nextToken = iText+1, nextChar
            tokens[#tokens+1] = LBSymbol:new(T.CLOSESQUARE, nextToken)

        elseif nextChar == "}" then
            -- regular brackets
            iText, nextToken = iText+1, text:sub(iText, iText)
            tokens[#tokens+1] = LBSymbol:new(T.CLOSECURLY, nextToken)

        elseif next2Char == ">>" or next2Char == "<<" then
            -- comparison
            iText, nextToken = iText+2, next2Char
            tokens[#tokens+1] = LBSymbol:new(T.BINARY_OP, nextToken)

        elseif next2Char == ">=" or next2Char == "<=" or next2Char == "~=" or next2Char == "==" then
            -- comparison
            iText, nextToken = iText+2, next2Char
            tokens[#tokens+1] = LBSymbol:new(T.COMPARISON, nextToken)

        elseif nextChar == ">" or nextChar == "<" then
            -- comparison
            iText, nextToken = iText+1, nextChar
            tokens[#tokens+1] = LBSymbol:new(T.COMPARISON, nextToken)

        elseif next2Char == "//" then
            -- floor (one math op not two)
            iText, nextToken = iText+2, next2Char
            tokens[#tokens+1] = LBSymbol:new(T.BINARY_OP, nextToken)

        elseif nextChar == "#" then
            -- all other math ops
            iText, nextToken = iText+1, nextChar
            tokens[#tokens+1] = LBSymbol:new(T.UNARY_OP, nextToken)
        
        elseif nextChar == "~" or nextChar == "-" then
            -- all other math ops
            iText, nextToken = iText+1, nextChar
            tokens[#tokens+1] = LBSymbol:new(T.MIXED_OP, nextToken)

        elseif lookup_math[nextChar] then
            -- all other math ops
            iText, nextToken = iText+1, nextChar
            tokens[#tokens+1] = LBSymbol:new(T.BINARY_OP, nextToken)


        elseif nextSectionEquals(text, iText, "...") then
            -- varargs
            iText, nextToken = iText+3, text:sub(iText, iText+2)
            tokens[#tokens+1] = LBSymbol:new(T.VARARGS, nextToken)

        elseif next2Char == ".." then
            -- concat
            iText, nextToken = iText+2, next2Char
            tokens[#tokens+1] = LBSymbol:new(T.BINARY_OP, nextToken)

        elseif nextChar == "=" then
            -- assignment
            iText, nextToken = iText+1, nextChar
            tokens[#tokens+1] = LBSymbol:new(T.ASSIGN, nextToken)

        elseif lookup_alpha[nextChar] then
            -- keywords & identifier
            iText, nextToken = LBStr.getTextIncluding(text, iText, "[%a_][%w_]*")
            local keyword = tokenizekeyword(nextToken)
            if keyword then
                tokens[#tokens+1] = LBSymbol:new(keyword, nextToken)
            else
                tokens[#tokens+1] = LBSymbol:new(T.IDENTIFIER, nextToken)
            end

        elseif lookup_ws[nextChar] then --nextSectionIs(text, iText, "%s") then
            -- whitespace
            iText, nextToken = LBStr.getTextIncluding(text, iText, "%s*")
            tokens[#tokens+1] = LBSymbol:new(T.WHITESPACE, nextToken)

        elseif next2Char == "0x" and nextSectionIs(text, iText, "0x%x+") then
            -- hex 
            iText, nextToken = LBStr.getTextIncluding(text, iText, "0x%x+")
            tokens[#tokens+1] = LBSymbol:new(T.HEX, nextToken)

        elseif lookup_digit[nextChar] and nextSectionIs(text, iText, "%d*%.?%d+") then 
            -- number
            iText, nextToken = LBStr.getTextIncluding(text, iText, "%d*%.?%d+")
            tokens[#tokens+1] = LBSymbol:new(T.NUMBER, nextToken)

        elseif nextChar == "." then
            -- chain access
            iText, nextToken = iText+1, nextChar
            tokens[#tokens+1] = LBSymbol:new(T.DOTACCESS, nextToken)

        elseif next2Char == "::" then
            -- chain access
            iText, nextToken = iText+1, next2Char
            tokens[#tokens+1] = LBSymbol:new(T.GOTOMARKER, nextToken)

        elseif nextChar == ":" then
            -- chain access
            iText, nextToken = iText+1, nextChar
            tokens[#tokens+1] = LBSymbol:new(T.COLONACCESS, nextToken)

        else
            error(lineInfo:toString() .. "\nCan't process symbol \"" .. text:sub(iText, iText+10) .. "...\"\n\n\"" .. text:sub(math.max(0, iText-20), iText+20) .. "...\"")
        end
        tokens[#tokens].lineInfo = lineInfo

        -- update line info
        local newLines = LBStr.find(nextToken, "\n")
        if #newLines > 0 then
            lineNumber = lineNumber + #newLines
            lastLineStartIndex = startIndex + newLines[#newLines].endIndex
        end
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
    tokens[#tokens+1] = LBSymbol:new(T.EOF,nil, getLineInfo())

    return associateRightWhitespaceAndComments(tokens)
end;