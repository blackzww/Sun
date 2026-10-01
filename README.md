<div align="center">

<img src="assets/sun.png" width="160" alt="Logo da Sun">

# Sun

### Programação, simplificada.

**Sun é uma linguagem criada para tornar Luau mais simples de escrever, ler e aprender.**

[Documentação](https://sun.vercel.app) • [Começar](#-começando) • [Exemplos](#-exemplos) • [Contribuir](#-contribuindo)

</div>

---

## ☀️ O que é Sun?

Sun é uma linguagem de programação construída sobre **Luau** com um objetivo simples:

> **Facilitar a programação sem tirar seu poder.**

Ela simplifica partes da sintaxe de Luau que podem ser desnecessariamente complicadas, principalmente para quem está começando.

Ao mesmo tempo, Sun mantém compatibilidade com APIs e bibliotecas existentes.

Você pode escrever:

```sun
repetir 3
    mostrar("Olá!")
fim
```

Em vez de:

```lua
for i = 1, 3 do
    print("Olá!")
end
```

Sun não tenta reinventar tudo.

Se uma API já é simples, você continua usando ela normalmente.

---

## ✨ Exemplos

### Variáveis

```sun
nome = "Black"
idade = 18
ativo = verdadeiro

mostrar(nome)
```

### Condições

```sun
idade = 18

se idade => 18 entao
    mostrar("Maior de idade")
senao
    mostrar("Menor de idade")
fim
```

Sun também possui `senaose`:

```sun
vida = 50

se vida > 80 entao
    mostrar("Vida alta")
senaose vida > 30 entao
    mostrar("Vida média")
senao
    mostrar("Vida baixa")
fim
```

### Repetições

```sun
repetir 5
    mostrar("Olá!")
fim
```

### Loop numérico

```sun
para i de 1 ate 10
    mostrar(i)
fim
```

### Listas

```sun
nomes = [
    "Black",
    "Joao",
    "Ana"
]

adicionar(nomes, "Pedro")

para i, nome em nomes
    mostrar(i)
    mostrar(nome)
fim
```

### Funções

```sun
funcao somar(a, b)
    retornar a + b
fim

resultado = somar(10, 20)

mostrar(resultado)
```

### Objetos

```sun
usuario = {
    nome: "Black",
    idade: 18,
    admin: verdadeiro
}

mostrar(usuario.nome)
```

---

## 🌙 Sun vs Luau

### Sun

```sun
nomes = [
    "Black",
    "Joao",
    "Ana"
]

para i, nome em nomes
    mostrar(i + ": " + nome)
fim
```

### Luau

```lua
local nomes = {
    "Black",
    "Joao",
    "Ana"
}

for i, nome in ipairs(nomes) do
    print(i .. ": " .. nome)
end
```

A ideia não é substituir o poder de Luau.

A ideia é precisar escrever e decorar **menos coisas para fazer a mesma tarefa**.

---

## 🎮 Roblox

Sun possui algumas facilidades para operações comuns no Roblox.

```sun
mostrar(em roblox vida)

em roblox velocidade = 50
```

Mas você **não fica preso** à sintaxe simplificada.

A API normal do Roblox continua disponível:

```sun
Players = game:GetService("Players")
player = Players.LocalPlayer

parte = Instance.new("Part")
parte.Parent = workspace
```

Isso significa que você pode usar recursos existentes sem esperar que a Sun crie uma versão própria deles.

---

## 📦 Bibliotecas Luau

Sun foi projetada para continuar funcionando com bibliotecas Luau.

Por exemplo:

```sun
MinhaLib = carregar "URL"
```

Depois disso, a API original da biblioteca pode continuar sendo usada:

```sun
Window = MinhaLib:CreateWindow({
    Title = "Meu projeto",
    Icon = "rbxassetid://123"
})
```

A Sun simplifica a **linguagem**, não renomeia APIs externas sem necessidade.

---

## 🚀 Começando

Carregue a Sun:

```lua
local Sun = loadstring(game:HttpGet("URL_DA_SUN"))()
```

Depois escreva seu código:

```lua
Sun[[
    nome = "Mundo"

    mostrar("Olá " + nome)

    repetir 3
        mostrar("Sun!")
    fim
]]
```

Pronto.

---

## 📖 Sintaxe

| Sun | Função |
| --- | --- |
| `mostrar(...)` | Mostra um valor |
| `se ... entao` | Cria uma condição |
| `senaose` | Outra condição |
| `senao` | Caso contrário |
| `cs` | Atalho para `senao` |
| `fim` | Finaliza um bloco |
| `repetir n` | Repete N vezes |
| `enquanto` | Repete enquanto uma condição for verdadeira |
| `para item em lista` | Percorre uma lista |
| `para i, item em lista` | Percorre índice e valor |
| `para i de 1 ate 10` | Loop numérico |
| `funcao` | Cria uma função |
| `retornar` | Retorna um valor |
| `parar` | Interrompe um loop |
| `continuar` | Vai para a próxima repetição |
| `verdadeiro` | Valor verdadeiro |
| `falso` | Valor falso |
| `nulo` | Ausência de valor |
| `?=` | Diferente |
| `=>` | Maior ou igual |
| `+=` | Soma e atualiza |
| `-=` | Subtrai e atualiza |
| `e` | E lógico |
| `ou` | OU lógico |
| `nao` | Negação |

---

## 🧰 Funções úteis

### Mostrar

```sun
mostrar("Olá!")
```

### Esperar

```sun
esperar 1 segundo
```

```sun
esperar 500 ms
```

### Tamanho

```sun
nomes = ["A", "B", "C"]

mostrar(tamanho(nomes))
```

### Adicionar

```sun
adicionar(nomes, "D")
```

### Remover

```sun
remover(nomes, 2)
```

---

## 🧠 Filosofia

A Sun segue uma regra principal:

> **Tudo que puder ser simplificado sem criar confusão deve ser simplificado. O resto continua compatível com Luau.**

Por isso:

```sun
repetir 5
    mostrar("Olá")
fim
```

é simplificado.

Mas:

```sun
game:GetService("Players")
```

continua reconhecível.

Não existe motivo para transformar uma API simples em outra API só para ela parecer diferente.

---

## 🗺️ Projeto

A documentação oficial ficará disponível em:

**https://sun.vercel.app**

O site terá documentação completa, guia para iniciantes, referência da linguagem e playground.

---

## 🤝 Contribuindo

Sun é um projeto **open source**.

Contribuições são bem-vindas.

Para contribuir:

1. Faça um fork do repositório.
2. Crie uma branch para sua alteração.
3. Faça e teste suas mudanças.
4. Abra um Pull Request explicando o que foi alterado.

Encontrou um bug? Abra uma **Issue** com um exemplo que reproduza o problema.

---

## 📜 Licença

Sun é distribuída sob a licença **MIT**.

Você pode usar, modificar e distribuir o projeto seguindo os termos da licença.

---

<div align="center">

<img src="assets/sun.png" width="90" alt="Sun">

### Sun

**Programação, simplificada.**

</div>