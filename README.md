# Roube um Kaiju

Jogo de Roblox no estilo "Steal a …": roube filhotes de kaiju nas zonas, leve para a sua base, veja eles crescerem até virar Titã e gerar dinheiro, e proteja a base dos outros jogadores.

O conceito completo (mercado, monetização e plano) está em [`docs/IDEIA_DO_JOGO.md`](docs/IDEIA_DO_JOGO.md).

## Como abrir no Roblox Studio

**Jeito rápido (sem instalar nada):**

1. Gere o arquivo do jogo: `rojo build default.project.json -o build/RoubeUmKaiju.rbxlx` (ou use o arquivo `.rbxlx` enviado na conversa).
2. Abra `RoubeUmKaiju.rbxlx` no Roblox Studio.
3. Clique em **Play** (F5). Para testar roubo entre jogadores: aba **Test** → **Clients and Servers** → 2 jogadores → **Start**.

**Jeito de desenvolvimento (sincroniza o código ao vivo):**

1. Instale o [Rojo](https://rojo.space) (CLI + plugin do Studio).
2. Rode `rojo serve` na pasta do projeto.
3. No Studio, abra um place vazio, abra o plugin do Rojo e clique em **Connect**.

**Salvamento no Studio:** para testar o DataStore no Studio, publique o place e ative *Game Settings → Security → Enable Studio Access to API Services*. Sem isso o jogo roda normalmente em "modo memória" (nada é salvo) e avisa no Output.

**Máximo de jogadores:** o mapa tem 8 bases. Configure *Game Settings → Places → Max Players = 8* ao publicar.

## O que já funciona (Fase 1)

- Mapa gerado por código: 8 bases, 5 zonas (Praia, Floresta, Vulcão, Geleira, Abismo) com ninhos e decoração.
- 15 kaijus em 7 raridades e 5 mutações (Dourado, Diamante, Neon, Radioativo), modelos 3D feitos por peças.
- Roubar filhote do ninho (tecla **E**), levar na cabeça e depositar entrando na sua base.
- Guardião ("Mãe Kaiju") em cada zona, que persegue quem rouba. Quem for pego perde o filhote.
- Crescimento em tempo real: Filhote → Jovem → Adulto → Titã. O modelo cresce e a renda sobe.
- Renda passiva acumulada no coletor da base (pise para coletar).
- Roubo entre jogadores (segurar **E** no kaiju de outra base) e botão de trancar a base por 45 s.
- Luva do **Tapa**: derruba o kaiju de quem está carregando. Kaiju derrubado volta para casa em 15 s.
- Esteira de velocidade com upgrades, desbloqueio de espaços na base, venda de kaiju (tecla **F**).
- Salvamento no DataStore, renda e crescimento offline (até 2 h, 50% da renda), anúncio de kaiju raro para o servidor.

## Estrutura

```
src/
  shared/              ReplicatedStorage.Shared (servidor e cliente)
    Config.luau          todos os números de balanceamento
    KaijuData.luau       catálogo de kaijus e guardiões
    KaijuModel.luau      monta os modelos 3D a partir de peças
    Format, Util, Remotes
  server/              ServerScriptService.Server
    init.server.luau     inicia os serviços
    Services/            Map, Data, Economy, Plot, Kaiju, Nest, Guard, Character, Slap, Player
  client/              StarterPlayerScripts.Client
    HUD, PromptFilter, Effects
tools/
  export_kaijus.luau   exporta a geometria dos kaijus para a galeria de aprovação
  luau-tools/          verificador de sintaxe e runner de Luau (Rust)
```

## Verificações

```sh
stylua --check src                                   # formatação
tools/luau-tools/target/release/luaucheck $(find src -name "*.luau")   # sintaxe
rojo sourcemap default.project.json -o sourcemap.json
luau-lsp analyze --platform=roblox --sourcemap=sourcemap.json \
  --definitions=@roblox=globalTypes.d.luau src        # tipos (definições do luau-lsp)
```

Para compilar as ferramentas: `cargo build --release --manifest-path tools/luau-tools/Cargo.toml`.
