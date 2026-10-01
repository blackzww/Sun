<div align="center">

<img src="assets/sun.png" width="150" alt="Sun">

# Sun

### Programação, simplificada.

Uma linguagem simples construída sobre **Luau**, criada para facilitar a escrita e leitura de código sem abandonar o ecossistema Luau.

[Documentação](https://sunlang.vercel.app) • [Exemplos](#-exemplo) • [Contribuir](#-open-source)

</div>

---

## 🚀 Começando

Carregue a Sun:

```lua
local Sun = loadstring(game:HttpGet("URL_RAW_DO_SUN_LUA"))()
```

E escreva:

```lua
Sun[[
    nome = "Mundo"

    mostrar("Olá " + nome)

    repetir 3
        mostrar("Sun!")
    fim
]]
```

É isso.

## ☀️ O que é a Sun?

Sun simplifica partes do Luau que podem ser mais trabalhosas de escrever ou aprender.

### Sun

```sun
para i de 1 ate 5
    mostrar("Olá!")
fim
```

### Luau

```lua
for i = 1, 5 do
    print("Olá!")
end
```

A Sun não tenta substituir APIs existentes. Código como:

```lua
Players = game:GetService("Players")
parte = Instance.new("Part")
```

continua familiar.

## ✨ Exemplo

```sun
nome = "Black"
idade = 18

se idade => 18 entao
    mostrar("Olá " + nome)
senao
    mostrar("Você é menor de idade")
fim

nomes = [
    "Ana",
    "Joao",
    "Pedro"
]

adicionar(nomes, nome)

para i, jogador em nomes
    mostrar(i)
    mostrar(jogador)
fim
```

## 🎮 Roblox

A Sun possui atalhos para algumas operações comuns:

```sun
mostrar(em roblox vida)

em roblox velocidade = 50
```

Mas a API original continua disponível:

```lua
Players = game:GetService("Players")
player = Players.LocalPlayer
```

## 📦 Bibliotecas

Bibliotecas Luau podem manter suas APIs originais:

```sun
MinhaLib = carregar "URL"

Window = MinhaLib:CreateWindow({
    Title = "Meu projeto"
})
```

A Sun simplifica a linguagem sem tentar renomear todo o ecossistema.

## 🤖 Sobre o projeto

A Sun foi desenvolvida com **forte auxílio de inteligência artificial**, incluindo partes de sua implementação, documentação e desenvolvimento inicial.

Por isso, o projeto não deve ser tratado como uma implementação perfeita ou imutável. Bugs, comportamentos inesperados e decisões que podem ser melhoradas são possíveis.

O código é propositalmente aberto e legível.

Você pode:

- estudar como a Sun funciona;
- modificar a linguagem;
- criar sua própria versão;
- corrigir bugs;
- adicionar recursos;
- enviar melhorias ao projeto.

## 🔓 Open Source

Sun é um projeto **open source e modificável**.

O objetivo não é esconder o funcionamento da linguagem. O código deve continuar simples o suficiente para que outras pessoas consigam abrir o `sun.lua` e entender o que está acontecendo.

Pull Requests e Issues são bem-vindos.

## 📖 Documentação

A referência completa da linguagem ficará na documentação:

**https://usesun.vercel.app**

O README serve apenas como introdução rápida.

## 📜 Licença

Sun é distribuída sob a **MIT License**.

Você pode usar, modificar, estudar e redistribuir o projeto seguindo os termos da licença.

---

<div align="center">

<img src="assets/sun.png" width="70" alt="Sun">

**Sun — Programação, simplificada.**

</div>
