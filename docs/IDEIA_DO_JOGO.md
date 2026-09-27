# Roube um Kaiju (Steal a Kaiju): proposta de jogo

> Pesquisa de mercado e documento de conceito, setembro de 2026.

## 1. O que está funcionando no Roblox agora

| Jogo | Estado (set/2026) | O que ensina |
|---|---|---|
| **Steal An Egg** | Lançado em 25/07/2026, é o jogo nº 1 com ~1,3–2M jogadores simultâneos e mais de 3,1 bi de visitas em menos de 2 meses | O ciclo "roubar → levar pra base → gerar renda passiva" continua explodindo |
| **Steal a Brainrot** | Recorde de 25,8M simultâneos (out/2025); estimativas de US$ 3–11M/mês | Personagens colecionáveis e memeáveis + troll/roubo entre jogadores = viralidade |
| **Grow a Garden** | Rivalizou com Steal a Brainrot em 2025 | Timers longos (plantar/chocar) fazem o jogador voltar várias vezes ao dia |
| Clones de "Steal a …" | Dezenas de clones com dezenas de milhares de jogadores | O gênero ainda tem demanda, mas clone puro disputa migalhas |

**Ciclo base do gênero (Steal An Egg):**
treinar velocidade na esteira → correr até ninhos guardados → pegar o ovo (tecla E) → voltar vivo pra base → chocar (timer, com raridades e mutações) → o pet gera dinheiro por segundo → comprar upgrades de base e esteira → alcançar zonas mais distantes e roubar de outros jogadores.

**Por que o gênero dá dinheiro:**
1. **Perder dói.** Ser roubado cria vontade imediata de pagar por defesa (cadeados, armadilhas, escudos).
2. **Roubar é divertido e rende clipe.** Isso gera TikTok e YouTube de graça.
3. **Renda passiva + timers** trazem o jogador de volta várias vezes ao dia (retenção D1/D7 alta).
4. **Colecionáveis raros com mutações** dão status social e motivam compras de sorte e velocidade.

## 2. A ideia: **Roube um Kaiju** (EN: *Steal a Kaiju*)

**Pitch em uma frase:** roube filhotes de kaiju (monstros gigantes) dos ninhos e das bases dos outros jogadores. Na sua base, eles **crescem de verdade**, ficam enormes e visíveis do mapa inteiro, e quanto maiores, mais dinheiro geram. Só que também ficam mais cobiçados.

### O diferencial (o que o Steal An Egg não tem)

| Mecânica | Como funciona | Por que prende / monetiza |
|---|---|---|
| **Crescimento visível** | O kaiju passa por Filhote → Jovem → Adulto → Titã (timer real, como no Grow a Garden). O modelo 3D escala de tamanho | Um Titã de 40 studs na sua base é flex visível pro servidor inteiro. Gera print e clipe |
| **Risco x recompensa no roubo** | Filhote é leve (você corre rápido). Adulto deixa você lento. Titã precisa de **2 jogadores** pra carregar | Cria cooperação ou traição entre amigos e jogadas épicas pra clipe |
| **Fusão (merge)** | 2 kaijus iguais do mesmo estágio viram 1 do estágio seguinte, com chance de mutação | Mecânica comprovada no mobile. Dá uso pros repetidos |
| **Ataque Kaiju (evento de servidor)** | A cada 15 min, um kaiju chefe invade o mapa e todos cooperam pra derrotá-lo e ganhar ovos raros | Pico de atividade e momento "admin abuse" orgânico |
| **Mutações temáticas** | Dourado, Diamante, Neon, Radioativo, "Brasil" (evento), Lava… | Coleção infinita, fácil de expandir em updates semanais |

O tema kaiju funciona no mundo todo (Godzilla, Pacific Rim, Kaiju No. 8), gera silhuetas gigantes e marcantes pra thumbnail e aceita designs engraçados e memeáveis (ex.: "Tubarão-Kaiju de tênis", "Capivara Titã"), no mesmo espírito dos brainrots.

## 3. Ciclo de jogo (MVP)

```
Esteira (velocidade) ──► Zonas de ninho (1→6, mais longe = mais raro)
        ▲                        │ pega filhote (E)
        │                        ▼
  Upgrades ◄── $/seg ◄── Base: kaiju cresce (timer) ──► Fusão
        │                        ▲
        └── Defesa (cadeado, laser, armadilha) ◄── outros jogadores tentam roubar
```

- **Base:** 8 slots iniciais (compráveis até 30), porta com cadeado temporário (60 s de proteção após fechar).
- **Roubo PvP:** qualquer jogador pode entrar na sua base e carregar um kaiju. Se for atingido (tapa, armadilha), ele derruba o kaiju.
- **Rebirth:** reseta dinheiro e zonas em troca de um multiplicador permanente e acesso a uma nova ilha/bioma.
- **Offline:** o kaiju continua crescendo e gerando renda (com limite de horas, ampliável por gamepass).

## 4. Monetização

**Game Passes (compra única):**

| Passe | Preço sugerido (Robux) |
|---|---|
| VIP (chat tag, +20% renda, área VIP) | 299 |
| 2x Dinheiro | 399 |
| +1 Mão (carrega 2 filhotes) | 249 |
| Crescimento 2x | 499 |
| Renda offline 24 h | 199 |
| Base Grande (+10 slots) | 349 |

**Developer Products (recompráveis, onde está a receita recorrente):**
- Pular timer de crescimento (escala com o estágio): 25–199 R$
- Escudo de base 30 min / 2 h: 49 / 149 R$
- Armadilhas premium (laser, gaiola): 29–99 R$
- Sorte de mutação 15 min (x2 / x5): 79 / 199 R$
- "Roubo garantido" (teleporte de volta pra base carregando): 99 R$
- Ovo de evento (odds **sempre exibidas**, obrigatório pelas regras do Roblox para itens aleatórios pagos)
- Presentear itens pra amigos

**Outras fontes:** Premium Payouts (tempo de jogo de assinantes Premium), Rewarded Video Ads do Roblox e itens de avatar (UGC) dos kaijus mais famosos.

**Estimativa (conservadora, só pra ordem de grandeza):**
- 2.000 jogadores simultâneos em média ≈ 60–80 mil DAU
- ARPDAU típico do gênero ≈ 1–2 R$ → ~100 mil R$/dia ≈ 3M R$/mês
- DevEx (~US$ 0,0038/R$) ≈ **US$ 10–12 mil/mês**, antes de impostos e anúncios
- Com 20 mil simultâneos (nível "top 100"), a mesma conta passa de US$ 100 mil/mês

## 5. Plano de desenvolvimento

**Stack:** Roblox Studio + Luau, Rojo (código versionado neste repo), ProfileStore/DataStore pra salvar dados, arquitetura servidor-autoritativa (todo roubo e dinheiro validado no servidor, porque o gênero é alvo pesado de exploiters: já existem scripts de "auto steal" pro Steal An Egg).

| Fase | Duração | Entregas |
|---|---|---|
| 1. Protótipo | 1–2 semanas | Mapa cinza, esteira, 1 zona, carregar/roubar, base com slots, crescimento, renda, save |
| 2. MVP | 2–3 semanas | 20 kaijus, 3 zonas, fusão, mutações, loja com gamepasses/produtos, anti-exploit, UI mobile-first |
| 3. Lançamento suave | 1 semana | Ads do Roblox (US$ 50–200), medir retenção D1 > 25% e sessão > 15 min, ajustar economia |
| 4. Live ops | contínuo | Update **toda semana** (novo kaiju, evento, mutação). É isso que mantém o algoritmo do Roblox recomendando |

**Marketing:** thumbnail com Titã gigante + jogador roubando; ícone chamativo; título em inglês com tag PT-BR (o Brasil é um dos maiores mercados do Roblox); clipes curtos de roubos épicos no TikTok/Shorts; códigos de resgate pra criadores de conteúdo.

## 6. Riscos e como mitigar

| Risco | Mitigação |
|---|---|
| Gênero saturado de clones | Diferencial claro (crescimento visível + carregar em dupla + ataque kaiju) já na thumbnail |
| Exploiters (auto-steal, speed hack) | Servidor valida distância, velocidade e posse; rate limits; logs |
| Regras do Roblox (itens aleatórios pagos, público infantil) | Exibir odds, nada de "gamble" puro, seguir as Community Standards e as restrições de idade |
| Economia quebrar (inflação) | Planilha de balanceamento antes do lançamento; rebirth como dreno de dinheiro |
| Tendência passar | Motor de "roubar → crescer → renda" reaproveitável pra reskins rápidos se o tema kaiju não pegar |

## 7. Alternativas consideradas

1. **Roube uma Fruta Gigante:** Grow a Garden + roubo. Fácil de fazer, mas muito próximo dos dois líderes.
2. **Roube um Carro (Tuning):** roubar carros e tunar na garagem. Público bom, mas modelagem cara e física complicada.
3. **Roube um Fóssil:** cavar e roubar ossos pra montar dinossauros. Legal, mas o ciclo é mais lento e menos viral.

**Kaiju foi escolhido** pelo impacto visual (gigantes no mapa), pela mecânica social de carregar em dupla e pela facilidade de lançar conteúdo novo toda semana.

## Fontes

- [Steal An Egg: guia para iniciantes (Sportskeeda)](https://www.sportskeeda.com/roblox-news/steal-an-egg-a-beginner-s-guide)
- [Steal an Egg Beginner Guide (games.gg)](https://games.gg/roblox/guides/steal-an-egg-beginner-guide/)
- [Best Roblox games, setembro de 2026 (Sportskeeda)](https://www.sportskeeda.com/roblox-news/best-roblox-games-to-play-right-now)
- [Most Played Roblox Games (rblxdb)](https://rblxdb.com/charts/most-played)
- [Steal a Brainrot (Wikipedia)](https://en.wikipedia.org/wiki/Steal_a_Brainrot)
- [Creator Exchange: receita estimada do Steal a Brainrot](https://x.com/CreatorExc/status/1952868682096574520?lang=en)
- [The 10 Highest-Earning Roblox Games in 2026 (RoWatcher)](https://rowatcher.com/news/the-10-highest-earning-roblox-games-in-2026-and-what-they-mean-for-the-platform)
- [The Attack of the Roblox Clones (Plagiarism Today)](https://www.plagiarismtoday.com/2026/09/17/the-attack-of-the-roblox-clones/)
