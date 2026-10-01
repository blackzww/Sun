local Sun = {
    nome = "Sun",
    versao = "1.0.0",
    debug = false,
}

local function trim(text)
    return (tostring(text):gsub("^%s+", ""):gsub("%s+$", ""))
end

local function linesOf(source)
    source = source:gsub("\r\n", "\n"):gsub("\r", "\n")
    if source:sub(-1) ~= "\n" then
        source ..= "\n"
    end
    local lines = {}
    for line in source:gmatch("(.-)\n") do
        lines[#lines + 1] = line
    end
    return lines
end

local function lineCount(text)
    local _, count = text:gsub("\n", "\n")
    return count + 1
end

local function distance(a, b)
    local previous = {}
    for j = 0, #b do
        previous[j] = j
    end
    for i = 1, #a do
        local current = {[0] = i}
        for j = 1, #b do
            local cost = a:sub(i, i) == b:sub(j, j) and 0 or 1
            current[j] = math.min(
                current[j - 1] + 1,
                previous[j] + 1,
                previous[j - 1] + cost
            )
        end
        previous = current
    end
    return previous[#b]
end

local words = {
    "mostrar", "esperar", "se", "entao", "senaose", "senao",
    "casocontrario", "cs", "repetir", "enquanto", "funcao",
    "retornar", "para", "de", "ate", "em", "roblox", "quando",
    "parar", "continuar", "verdadeiro", "falso", "nulo", "fim",
    "adicionar", "remover", "tamanho", "carregar"
}

local function suggest(word)
    if not word or #word < 4 then
        return nil
    end
    local best, score
    for _, candidate in ipairs(words) do
        local value = distance(word, candidate)
        if score == nil or value < score then
            best, score = candidate, value
        end
    end
    if score and score <= 2 then
        return best
    end
end

local function sourceError(lines, number, message, token)
    local raw = lines[number] or ""
    local first = raw:find("%S") or 1
    local width = math.max(1, #(token or trim(raw)))
    local caret = string.rep(" ", first - 1) .. string.rep("^", width)
    error(("[SUN ERRO] Linha %d\n\n%s\n%s\n\n%s"):format(number, raw, caret, message), 0)
end

local function stripInlineComment(line)
    local quote, escaped
    local i = 1
    while i <= #line do
        local char = line:sub(i, i)
        local nextChar = line:sub(i + 1, i + 1)
        if quote then
            if escaped then
                escaped = false
            elseif char == "\\" then
                escaped = true
            elseif char == quote then
                quote = nil
            end
        elseif char == '"' or char == "'" then
            quote = char
        elseif char == "/" and nextChar == "/" then
            return line:sub(1, i - 1)
        end
        i += 1
    end
    return line
end

local function mapOutsideStrings(text, outside, stringHandler)
    local result = {}
    local buffer = {}
    local quote, escaped

    local function flushOutside()
        if #buffer > 0 then
            result[#result + 1] = outside(table.concat(buffer))
            buffer = {}
        end
    end

    local stringBuffer = {}
    local function flushString()
        local value = table.concat(stringBuffer)
        result[#result + 1] = stringHandler and stringHandler(value) or value
        stringBuffer = {}
    end

    for i = 1, #text do
        local char = text:sub(i, i)
        if quote then
            stringBuffer[#stringBuffer + 1] = char
            if escaped then
                escaped = false
            elseif char == "\\" then
                escaped = true
            elseif char == quote then
                quote = nil
                flushString()
            end
        elseif char == '"' or char == "'" then
            flushOutside()
            quote = char
            stringBuffer[#stringBuffer + 1] = char
        else
            buffer[#buffer + 1] = char
        end
    end

    if quote then
        flushString()
    else
        flushOutside()
    end

    return table.concat(result)
end

local function splitTopLevel(text, separator)
    local parts = {}
    local current = {}
    local quote, escaped
    local round, square, curly = 0, 0, 0

    for i = 1, #text do
        local char = text:sub(i, i)
        if quote then
            current[#current + 1] = char
            if escaped then
                escaped = false
            elseif char == "\\" then
                escaped = true
            elseif char == quote then
                quote = nil
            end
        else
            if char == '"' or char == "'" then
                quote = char
            elseif char == "(" then
                round += 1
            elseif char == ")" then
                round -= 1
            elseif char == "[" then
                square += 1
            elseif char == "]" then
                square -= 1
            elseif char == "{" then
                curly += 1
            elseif char == "}" then
                curly -= 1
            end

            if char == separator and round == 0 and square == 0 and curly == 0 then
                parts[#parts + 1] = trim(table.concat(current))
                current = {}
                continue
            end
            current[#current + 1] = char
        end
    end

    parts[#parts + 1] = trim(table.concat(current))
    return parts
end

local function hasString(text)
    local found = false
    mapOutsideStrings(text, function(value)
        return value
    end, function(value)
        found = true
        return value
    end)
    return found
end

local function interpolate(token)
    if #token < 2 then
        return token
    end

    local quote = token:sub(1, 1)
    local content = token:sub(2, -2)
    local pieces = {}
    local position = 1
    local found = false

    while true do
        local startAt, endAt, path = content:find("{([%a_][%w_%.]*)}", position)
        if not startAt then
            break
        end
        found = true
        if startAt > position then
            pieces[#pieces + 1] = quote .. content:sub(position, startAt - 1) .. quote
        end
        pieces[#pieces + 1] = path
        position = endAt + 1
    end

    if not found then
        return token
    end

    if position <= #content then
        pieces[#pieces + 1] = quote .. content:sub(position) .. quote
    end

    local value = '""'
    for _, piece in ipairs(pieces) do
        value = "__sun_add(" .. value .. ", " .. piece .. ")"
    end
    return value
end

local function transformWords(text)
    return mapOutsideStrings(text, function(part)
        part = part:gsub("=>", ">=")
        part = part:gsub("%?=", "~=")
        part = part:gsub("(%f[%a_])verdadeiro(%f[^%w_])", "%1true%2")
        part = part:gsub("(%f[%a_])falso(%f[^%w_])", "%1false%2")
        part = part:gsub("(%f[%a_])nulo(%f[^%w_])", "%1nil%2")
        part = part:gsub("(%f[%a_])nao(%f[^%w_])", "%1not%2")
        part = part:gsub("(%f[%a_])e(%f[^%w_])", "%1and%2")
        part = part:gsub("(%f[%a_])ou(%f[^%w_])", "%1or%2")
        part = part:gsub("([%a_][%w_]*)%s*:%s+", "%1 = ")
        part = part:gsub("em%s+roblox%s+([%a_][%w_%.]*)", function(path)
            return ('__sun_roblox_get("%s")'):format(path)
        end)
        return part
    end, interpolate)
end

local function transformStringPlus(expression)
    local parts = splitTopLevel(expression, "+")
    if #parts <= 1 or not hasString(expression) then
        return expression
    end
    local value = parts[1]
    for i = 2, #parts do
        value = "__sun_add(" .. value .. ", " .. parts[i] .. ")"
    end
    return value
end

local function transformExpression(expression)
    expression = trim(expression)

    local url = expression:match('^carregar%s+(["\'].-["\'])$')
    if url then
        return "__sun_load(" .. url .. ")"
    end

    if expression:sub(1, 1) == "[" and expression:sub(-1) == "]" then
        expression = "{" .. expression:sub(2, -2) .. "}"
    end

    expression = transformWords(expression)
    expression = transformStringPlus(expression)
    return expression
end

local function transformExpressionList(text)
    local parts = splitTopLevel(text, ",")
    for i, part in ipairs(parts) do
        parts[i] = transformExpression(part)
    end
    return table.concat(parts, ", ")
end

local function isRawLuau(line)
    return line:match("^if%s+")
        or line:match("^elseif%s+")
        or line == "else"
        or line:match("^end[,;]?$")
        or line:match("^for%s+")
        or line:match("^while%s+")
        or line == "repeat"
        or line:match("^until%s+")
        or line:match("^function%s+")
        or line:match("^local%s+function%s+")
        or line:match("^return[%s;]")
        or line == "return"
        or line == "break"
        or line == "continue"
        or line:match("^type%s+")
        or line:match("^export%s+type%s+")
        or line:find(":", 1, true) ~= nil
end

local function parseParameters(text)
    text = trim(text)
    if text == "" then
        return {}, {}
    end

    local parameters, defaults = {}, {}
    for _, item in ipairs(splitTopLevel(text, ",")) do
        local name, default = item:match("^([%a_][%w_]*)%s*=%s*(.+)$")
        if name then
            parameters[#parameters + 1] = name
            defaults[#defaults + 1] = {name = name, value = transformExpression(default)}
        else
            item = trim(item)
            if not item:match("^[%a_][%w_]*$") then
                error("[SUN ERRO] Parâmetro inválido: " .. item, 0)
            end
            parameters[#parameters + 1] = item
        end
    end
    return parameters, defaults
end

local runtime = [==[
local function mostrar(...)
    print(...)
end

local function tamanho(value)
    if value == nil then
        return 0
    end
    return #value
end

local function adicionar(list, value, index)
    if index == nil then
        table.insert(list, value)
    else
        table.insert(list, index, value)
    end
    return list
end

local function remover(list, index)
    return table.remove(list, index or #list)
end

local function __sun_add(a, b)
    if type(a) == "number" and type(b) == "number" then
        return a + b
    end
    return tostring(a) .. tostring(b)
end

local function __sun_load(url)
    if not game then
        error("[SUN] Este ambiente não possui game.", 0)
    end
    if type(loadstring) ~= "function" then
        error("[SUN] Este ambiente não possui loadstring.", 0)
    end
    local ok, source = pcall(function()
        return game:HttpGet(url)
    end)
    if not ok then
        error("[SUN] Não consegui baixar: " .. tostring(source), 0)
    end
    local chunk, err = loadstring(source)
    if not chunk then
        error("[SUN] Não consegui compilar a library: " .. tostring(err), 0)
    end
    return chunk()
end

local function __sun_player()
    return game:GetService("Players").LocalPlayer
end

local function __sun_character()
    local player = __sun_player()
    if not player then
        error("[SUN] Jogador local não encontrado.", 0)
    end
    return player.Character or player.CharacterAdded:Wait()
end

local function __sun_humanoid()
    local character = __sun_character()
    return character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid")
end

local function __sun_root()
    local character = __sun_character()
    return character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart
end

local proxyTargets = setmetatable({}, {__mode = "k"})

local function unwrap(value)
    return proxyTargets[value] or value
end

local function wrap(value, kind)
    if value == nil then
        return nil
    end
    local valueType = typeof(value)
    if valueType ~= "Instance" and type(value) ~= "table" then
        return value
    end

    local proxy = {}
    proxyTargets[proxy] = value

    setmetatable(proxy, {
        __index = function(_, key)
            local name = string.lower(tostring(key))

            if kind == "player" then
                if name == "nome" then return value.Name end
                if name == "personagem" then return wrap(__sun_character(), "character") end
                if name == "cabeca" then return wrap(__sun_character():FindFirstChild("Head"), "instance") end
                if name == "vida" then return __sun_humanoid().Health end
                if name == "velocidade" then return __sun_humanoid().WalkSpeed end
                if name == "pulo" then return __sun_humanoid().JumpPower end
            elseif kind == "character" then
                if name == "nome" then return value.Name end
                if name == "cabeca" then return wrap(value:FindFirstChild("Head"), "instance") end
                if name == "humanoide" then return wrap(__sun_humanoid(), "instance") end
                if name == "raiz" then return wrap(__sun_root(), "instance") end
                if name == "vida" then return __sun_humanoid().Health end
                if name == "velocidade" then return __sun_humanoid().WalkSpeed end
                if name == "pulo" then return __sun_humanoid().JumpPower end
            end

            if name == "nome" then
                local ok, result = pcall(function() return value.Name end)
                if ok then return result end
            elseif name == "posicao" then
                local ok, result = pcall(function() return value.Position end)
                if ok then return result end
            end

            local ok, result = pcall(function() return value[key] end)
            if not ok then
                return nil
            end

            if type(result) == "function" then
                return function(...)
                    local args = table.pack(...)
                    for i = 1, args.n do
                        args[i] = unwrap(args[i])
                    end
                    local returned = table.pack(result(value, table.unpack(args, 1, args.n)))
                    for i = 1, returned.n do
                        returned[i] = wrap(returned[i], "instance")
                    end
                    return table.unpack(returned, 1, returned.n)
                end
            end

            if typeof(result) == "Instance" then
                return wrap(result, "instance")
            end
            return result
        end,

        __newindex = function(_, key, newValue)
            newValue = unwrap(newValue)
            local name = string.lower(tostring(key))

            if kind == "player" or kind == "character" then
                if name == "vida" then __sun_humanoid().Health = newValue return end
                if name == "velocidade" then __sun_humanoid().WalkSpeed = newValue return end
                if name == "pulo" then __sun_humanoid().JumpPower = newValue return end
            end

            if name == "posicao" then
                local ok = pcall(function() value.Position = newValue end)
                if ok then return end
            end

            value[key] = newValue
        end,

        __tostring = function()
            return tostring(value)
        end,

        __len = function()
            return #value
        end,
    })

    return proxy
end

local roblox = setmetatable({}, {
    __index = function(_, key)
        local name = string.lower(tostring(key))
        if name == "jogador" then return wrap(__sun_player(), "player") end
        if name == "personagem" then return wrap(__sun_character(), "character") end
        if name == "humanoide" then return wrap(__sun_humanoid(), "instance") end
        if name == "cabeca" then return wrap(__sun_character():FindFirstChild("Head"), "instance") end
        if name == "raiz" then return wrap(__sun_root(), "instance") end
        if name == "vida" then return __sun_humanoid().Health end
        if name == "vidamaxima" or name == "vidamax" then return __sun_humanoid().MaxHealth end
        if name == "velocidade" then return __sun_humanoid().WalkSpeed end
        if name == "pulo" then return __sun_humanoid().JumpPower end
        if name == "posicao" then
            local root = __sun_root()
            return root and root.Position
        end
    end,

    __newindex = function(_, key, value)
        local name = string.lower(tostring(key))
        if name == "vida" then
            __sun_humanoid().Health = value
        elseif name == "velocidade" then
            __sun_humanoid().WalkSpeed = value
        elseif name == "pulo" then
            __sun_humanoid().JumpPower = value
        elseif name == "posicao" then
            local root = __sun_root()
            if typeof(value) == "Vector3" then
                root.CFrame = CFrame.new(value)
            elseif typeof(value) == "CFrame" then
                root.CFrame = value
            else
                error("[SUN] roblox.posicao espera Vector3 ou CFrame.", 0)
            end
        else
            error("[SUN] Não sei alterar roblox." .. tostring(key), 0)
        end
    end,
})

local function __sun_roblox_get(path)
    local current = roblox
    for part in tostring(path):gmatch("[^%.]+") do
        current = current[part]
        if current == nil then
            return nil
        end
    end
    return current
end

local function __sun_roblox_set(path, value)
    local parts = {}
    for part in tostring(path):gmatch("[^%.]+") do
        parts[#parts + 1] = part
    end
    if #parts == 1 then
        roblox[parts[1]] = value
        return
    end
    local current = roblox
    for i = 1, #parts - 1 do
        current = current[parts[i]]
        if current == nil then
            error("[SUN] Caminho Roblox não encontrado: " .. tostring(path), 0)
        end
    end
    current[parts[#parts]] = value
end
]==]

local runtimeLineCount = lineCount(runtime)

local function compile(source)
    if type(source) ~= "string" then
        error("[SUN] O código precisa ser texto.", 0)
    end

    local sourceLines = linesOf(source)
    local output, map = {}, {}
    local stack = {}
    local listDepth = 0
    local blockComment = false
    local knownFunctions = {}

    local function indent()
        return #stack
    end

    local function emit(code, sourceLine, forcedIndent)
        output[#output + 1] = string.rep("    ", forcedIndent == nil and indent() or forcedIndent) .. code
        map[#output] = sourceLine
    end

    local function push(kind, close)
        stack[#stack + 1] = {kind = kind, close = close or "end"}
    end

    local function pop(number)
        local frame = stack[#stack]
        if not frame then
            sourceError(sourceLines, number, "'fim' apareceu sem existir um bloco aberto.", "fim")
        end
        stack[#stack] = nil
        return frame
    end

    local function checkTypo(number, line)
        local first = line:match("^([%a_][%w_]*)")
        if not first or knownFunctions[first] then
            return
        end
        local candidate = suggest(first)
        if candidate and candidate ~= first then
            local looksLikeCall = line:match("^[%a_][%w_]*%s*%(") ~= nil
            local looksLikeCommand = not line:find("[%.:]", 1)
            if looksLikeCall or looksLikeCommand then
                sourceError(
                    sourceLines,
                    number,
                    ('"%s" não existe.\nTalvez você quis dizer "%s".'):format(first, candidate),
                    first
                )
            end
        end
    end

    for number, original in ipairs(sourceLines) do
        local raw = trim(original)

        if blockComment then
            if raw:find("]]", 1, true) then
                blockComment = false
            end
            continue
        end

        if raw:sub(1, 4) == "//[[" then
            if not raw:find("]]", 5, true) then
                blockComment = true
            end
            continue
        end

        local line = trim(stripInlineComment(original))
        if line == "" then
            continue
        end

        if listDepth > 0 then
            if line == "]" or line == "]," then
                listDepth -= 1
                emit(line == "]," and "}," or "}", number)
                continue
            end
            local comma = line:sub(-1) == ","
            local value = comma and trim(line:sub(1, -2)) or line
            emit(transformExpression(value) .. (comma and "," or ""), number)
            continue
        end

        if line == "fim" then
            local frame = pop(number)
            emit(frame.close, number, indent())
            continue
        end

        if line == "senao" or line == "casocontrario" or line == "cs" then
            local frame = stack[#stack]
            if not frame or frame.kind ~= "if" then
                sourceError(sourceLines, number, "'" .. line .. "' precisa estar dentro de um 'se'.", line)
            end
            emit("else", number, indent() - 1)
            continue
        end

        local elseifCondition = line:match("^senaose%s+(.+)%s+entao$")
        if elseifCondition then
            local frame = stack[#stack]
            if not frame or frame.kind ~= "if" then
                sourceError(sourceLines, number, "'senaose' precisa estar dentro de um 'se'.", "senaose")
            end
            emit("elseif " .. transformExpression(elseifCondition) .. " then", number, indent() - 1)
            continue
        end

        local callbackKey, callbackArgs = line:match("^([%a_][%w_]*)%s*:%s*funcao%s*(.-)%s*,?$")
        if callbackKey then
            callbackArgs = trim(callbackArgs)
            if callbackArgs:sub(1, 1) == "(" and callbackArgs:sub(-1) == ")" then
                callbackArgs = callbackArgs:sub(2, -2)
            end
            local parameters, defaults = parseParameters(callbackArgs)
            emit(callbackKey .. " = function(" .. table.concat(parameters, ", ") .. ")", number)
            push("callback", "end,")
            for _, default in ipairs(defaults) do
                emit("if " .. default.name .. " == nil then " .. default.name .. " = " .. default.value .. " end", number)
            end
            continue
        end

        local objectListKey = line:match("^([%a_][%w_]*)%s*:%s*%[$")
        if objectListKey then
            emit(objectListKey .. " = {", number)
            listDepth += 1
            continue
        end

        local objectKey, objectValue = line:match("^([%a_][%w_]*)%s*:%s*(.+)$")
        if objectKey then
            local comma = objectValue:sub(-1) == ","
            if comma then
                objectValue = trim(objectValue:sub(1, -2))
            end
            emit(objectKey .. " = " .. transformExpression(objectValue) .. (comma and "," or ""), number)
            continue
        end

        local showArgs = line:match("^mostrar%s*%((.*)%)$")
        if showArgs ~= nil then
            emit("mostrar(" .. transformExpressionList(showArgs) .. ")", number)
            continue
        end

        local waitMs = line:match("^esperar%s+(.+)%s+ms$") or line:match("^esperar%s+(.+)%s+milissegundos?$")
        if waitMs then
            emit("task.wait((" .. transformExpression(waitMs) .. ") / 1000)", number)
            continue
        end

        local waitSeconds = line:match("^esperar%s+(.+)%s+segundos?$")
        if waitSeconds then
            emit("task.wait(" .. transformExpression(waitSeconds) .. ")", number)
            continue
        end

        local waitValue = line:match("^esperar%s+(.+)$")
        if waitValue then
            emit("task.wait(" .. transformExpression(waitValue) .. ")", number)
            continue
        end

        local condition = line:match("^se%s+(.+)%s+entao$")
        if condition then
            emit("if " .. transformExpression(condition) .. " then", number)
            push("if")
            continue
        elseif line:match("^se%s+") then
            sourceError(sourceLines, number, "Condição incompleta. Use: se condição entao", "se")
        end

        local repeatCount = line:match("^repetir%s+(.+)$")
        if repeatCount then
            emit("for __sun_i_" .. number .. " = 1, " .. transformExpression(repeatCount) .. " do", number)
            push("loop")
            continue
        end

        local whileCondition = line:match("^enquanto%s+(.+)$")
        if whileCondition then
            emit("while " .. transformExpression(whileCondition) .. " do", number)
            push("loop")
            continue
        end

        local numericName, numericStart, numericEnd = line:match("^para%s+([%a_][%w_]*)%s+de%s+(.+)%s+ate%s+(.+)$")
        if numericName then
            emit("for " .. numericName .. " = " .. transformExpression(numericStart) .. ", " .. transformExpression(numericEnd) .. " do", number)
            push("loop")
            continue
        end

        local indexName, itemName, listExpression = line:match("^para%s+([%a_][%w_]*)%s*,%s*([%a_][%w_]*)%s+em%s+(.+)$")
        if indexName then
            emit("for " .. indexName .. ", " .. itemName .. " in ipairs(" .. transformExpression(listExpression) .. ") do", number)
            push("loop")
            continue
        end

        itemName, listExpression = line:match("^para%s+([%a_][%w_]*)%s+em%s+(.+)$")
        if itemName then
            emit("for _, " .. itemName .. " in ipairs(" .. transformExpression(listExpression) .. ") do", number)
            push("loop")
            continue
        end

        if line == "parar" then
            emit("break", number)
            continue
        end

        if line == "continuar" then
            emit("continue", number)
            continue
        end

        local functionName, functionArgs = line:match("^funcao%s+([%a_][%w_]*)%s*(.*)$")
        if functionName then
            functionArgs = trim(functionArgs)
            if functionArgs:sub(1, 1) == "(" and functionArgs:sub(-1) == ")" then
                functionArgs = functionArgs:sub(2, -2)
            end
            local parameters, defaults = parseParameters(functionArgs)
            knownFunctions[functionName] = true
            emit("function " .. functionName .. "(" .. table.concat(parameters, ", ") .. ")", number)
            push("function")
            for _, default in ipairs(defaults) do
                emit("if " .. default.name .. " == nil then " .. default.name .. " = " .. default.value .. " end", number)
            end
            continue
        end

        if line == "retornar" then
            emit("return", number)
            continue
        end

        local returnValue = line:match("^retornar%s+(.+)$")
        if returnValue then
            emit("return " .. transformExpressionList(returnValue), number)
            continue
        end

        if line == "quando jogador.personagem mudar" then
            emit("__sun_player().CharacterAdded:Connect(function(personagem)", number)
            push("event", "end)")
            continue
        elseif line == "quando jogador.morrer" then
            emit("__sun_humanoid().Died:Connect(function()", number)
            push("event", "end)")
            continue
        elseif line == "quando jogador.pular" then
            emit("__sun_humanoid().Jumping:Connect(function(ativo)", number)
            push("event", "end)")
            continue
        end

        local robloxPath, robloxValue = line:match("^em%s+roblox%s+([%a_][%w_%.]*)%s*=%s*(.+)$")
        if robloxPath then
            emit('__sun_roblox_set("' .. robloxPath .. '", ' .. transformExpression(robloxValue) .. ")", number)
            continue
        end

        local listPrefix = line:match("^(.-)%s*=%s*%[$")
        if listPrefix then
            emit(trim(listPrefix) .. " = {", number)
            listDepth += 1
            continue
        end

        local localName, localValue = line:match("^local%s+([%a_][%w_]*)%s*=%s*(.+)$")
        if localName then
            emit("local " .. localName .. " = " .. transformExpression(localValue), number)
            continue
        end

        local left, operator, right = line:match("^([%a_][%w_%.%[%]'\"]*)%s*([%+%-])=%s*(.+)$")
        if left then
            emit(left .. " " .. operator .. "= " .. transformExpression(right), number)
            continue
        end

        left, right = line:match("^([%a_][%w_%.%[%]'\"]*)%s*=%s*(.+)$")
        if left then
            emit(left .. " = " .. transformExpression(right), number)
            continue
        end

        if isRawLuau(line) then
            emit(line, number)
            continue
        end

        checkTypo(number, line)
        emit(transformWords(line), number)
    end

    if blockComment then
        sourceError(sourceLines, #sourceLines, "Comentário //[[ não foi fechado com ]].", "//[[")
    end

    if listDepth > 0 then
        sourceError(sourceLines, #sourceLines, "Existe uma lista '[' que não foi fechada com ']'.", "[")
    end

    if #stack > 0 then
        local frame = stack[#stack]
        sourceError(sourceLines, #sourceLines, "Existe um bloco '" .. frame.kind .. "' que não foi fechado com 'fim'.", "fim")
    end

    return runtime .. "\n\n" .. table.concat(output, "\n"), map, sourceLines
end

local function mappedError(message, map, sourceLines)
    local generatedLine = tonumber(tostring(message):match(":(%d+):"))
    if generatedLine then
        local bodyLine = generatedLine - runtimeLineCount - 1
        local sourceLine = map[bodyLine]
        if sourceLine then
            local raw = sourceLines[sourceLine] or ""
            local first = raw:find("%S") or 1
            local caret = string.rep(" ", first - 1) .. string.rep("^", math.max(1, #trim(raw)))
            return ("[SUN ERRO] Linha %d\n\n%s\n%s\n\n%s"):format(sourceLine, raw, caret, tostring(message))
        end
    end
    return "[SUN ERRO]\n" .. tostring(message)
end

function Sun.executar(source)
    local generated, map, sourceLines = compile(source)

    if Sun.debug then
        print("========== SUN -> LUAU ==========")
        print(generated)
        print("=================================")
    end

    if type(loadstring) ~= "function" then
        error("[SUN] Este ambiente não possui loadstring.", 0)
    end

    local chunk, compileError = loadstring(generated)
    if not chunk then
        error(mappedError(compileError, map, sourceLines), 0)
    end

    local returned = table.pack(pcall(chunk))
    if not returned[1] then
        error(mappedError(returned[2], map, sourceLines), 0)
    end

    return table.unpack(returned, 2, returned.n)
end

Sun.run = Sun.executar

return setmetatable(Sun, {
    __call = function(_, source)
        return Sun.executar(source)
    end,
})
