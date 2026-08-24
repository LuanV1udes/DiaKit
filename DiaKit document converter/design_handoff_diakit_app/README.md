# Handoff: DiaKit — App de Conversão DOC/DOCX → PDF

## Overview
DiaKit é um app mobile de "ferramentas do dia a dia". A primeira função é converter arquivos DOC/DOCX em PDF para impressão. O pacote cobre 6 telas (claro + escuro = 12 variantes) e a marca (logo).

## About the Design Files
Os arquivos `.dc.html` deste pacote são **referências de design em HTML** — protótipos estáticos mostrando aparência e conteúdo pretendidos, não código de produção. A tarefa é **recriar esses designs no ambiente real do app** (React Native, Flutter, SwiftUI, Kotlin/Compose etc. — o que já estiver em uso, ou a stack mais adequada se o projeto for novo), usando os padrões e bibliotecas nativas dessa stack. Não deve ser um WebView do HTML.

## Fidelity
**Alta fidelidade (hifi)**: cores, tipografia, espaçamento e conteúdo finais. Recrie pixel a pixel usando os componentes nativos da stack escolhida.

## Screens / Views

Todas as telas usam um canvas de referência de 390×844px (tamanho de iPhone), sem moldura de dispositivo (a moldura real vem do SO).

### 1. Splash / Onboarding
- **Purpose**: primeira tela ao abrir o app, apresenta a marca e a proposta de valor.
- **Layout**: coluna única, padding 40px/28px. Metade superior: ilustração central (documento → seta → documento com check) num card com fundo `surface`, bordas 1px, radius grande. Metade inferior: título, parágrafo, indicador de página (3 pontos, 1 ativo) e botão primário full-width.
- **Content**: título "DiaKit" (44px); texto "Ferramentas essenciais para o seu dia a dia, direto do bolso. Comece transformando seus documentos DOC e DOCX em PDF prontos para imprimir."; botão "Começar".

### 2. Home
- **Purpose**: hub principal, acesso à ferramenta ativa e prévia de ferramentas futuras.
- **Layout**: header com saudação + avatar (botão ícone circular); card em destaque (borda accent, ícone, título, descrição, seta) para "Converter para PDF"; seção "Em breve" com grid 2×2 de cards bloqueados (opacidade 55%, ícone de cadeado) para PDF→Word, Comprimir PDF, Assinar PDF, PDF→Imagem; tab bar inferior fixa (Início / Histórico / Perfil).
- **States**: cards "em breve" são não-clicáveis (disabled visual).

### 3. Fluxo de conversão (arquivo selecionado)
- **Purpose**: usuário escolhe e confirma o arquivo a converter.
- **Layout**: header com voltar + título; dropzone tracejada ("Toque para selecionar um arquivo", "DOC ou DOCX, até 25MB"); card do arquivo selecionado (ícone, nome, tamanho, botão remover "x"); nota de privacidade ("O arquivo é convertido no seu aparelho. Nada é enviado a servidores externos."); botão primário fixo no rodapé "Converter para PDF".
- **States a implementar**: vazio (sem arquivo) → arquivo selecionado (mostrado aqui) → convertendo (progresso) → concluído/erro.

### 4. Resultado / Download
- **Purpose**: confirma sucesso da conversão e oferece próximas ações.
- **Layout**: header com voltar + título "Conversão concluída"; centro: círculo com check, título "Seu arquivo está pronto!", card do arquivo gerado (.pdf); footer com 3 ações empilhadas: "Baixar PDF" (primário), "Compartilhar" (secundário), "Converter outro arquivo" (ghost/link).

### 5. Histórico
- **Purpose**: lista de conversões passadas, agrupadas por data.
- **Layout**: título "Histórico"; grupos por data ("Hoje", "Ontem", ...) cada um com linhas: ícone + nome do arquivo + hora/tamanho à esquerda, tag de status à direita (`Concluído` ou `Erro`); hairline entre linhas; tab bar inferior (aba Histórico ativa).
- **States**: linha de sucesso (tag accent "Concluído") vs. linha de falha (ícone file-x, tag outline "Erro").

### 6. Perfil / Configurações
- **Purpose**: dados da conta e preferências.
- **Layout**: avatar + nome + tag "Conta gratuita"; grupos de configuração em cards com linhas divididas por hairline: Preferências (Notificações, Idioma), Suporte (Ajuda, Enviar feedback); rodapé com versão do app; tab bar inferior (aba Perfil ativa).

### Telas desktop (13–17)
Versões desktop de Home, Converter, Resultado, Histórico e Perfil, no mesmo canvas de referência (1280×800px). Layout: sidebar fixa à esquerda (240px) com logo + navegação (Início/Histórico/Perfil, item ativo com fundo `accent-100` e texto `accent-700`); área de conteúdo à direita com o mesmo conteúdo das telas mobile, mas em layout mais largo (grids de 4 colunas em vez de 2, cards com `max-width` em vez de full-bleed, ações lado a lado em vez de empilhadas). Sem tab bar inferior — a navegação vive só na sidebar. Splash não tem versão desktop (é uma tela só de abertura do app mobile).

### Modo escuro
Todas as 6 telas têm uma variante escura: fundo passa de `--color-bg` claro para um marsala profundo (`#3a2220`), texto e ícones passam para tons claros, accent usa os degraus mais claros da rampa marsala/avelã para manter contraste. Nenhuma mudança estrutural — só troca de tokens de cor.

### Logo (`DiaKit Logo.dc.html`)
- Símbolo: documento com canto dobrado + check, traço (não preenchido), 2.5px stroke.
- Lockups: símbolo + wordmark (padrão e sobre fundo marsala), símbolo isolado, ícone de app (fundo sólido marsala + símbolo claro), wordmark isolado com tagline "Ferramentas do dia a dia".

## Interactions & Behavior
Mockup estático — sem protótipo clicável. O time de dev deve implementar:
- Navegação: Splash → Home; Home → Conversão (toque no card "Converter para PDF"); Conversão → Resultado (após sucesso); Resultado → Home (via "Converter outro arquivo") ou permanece; tab bar navega entre Home / Histórico / Perfil.
- Seleção de arquivo: abrir seletor de arquivos nativo do SO restrito a `.doc`/`.docx`, limite 25MB.
- Conversão: processamento local (a cópia indica "no seu aparelho, nada enviado a servidores externos" — validar se isso é viável tecnicamente ou se precisa ajustar a copy caso a conversão seja remota).
- Download/Compartilhar: usar as APIs nativas de compartilhamento/salvar arquivo do SO.
- Estados de erro (ex.: arquivo corrompido) devem seguir o padrão visto no Histórico (tag "Erro", ícone file-x).

## State Management
- Estado do arquivo em conversão: `idle | selected | converting | success | error`.
- Histórico: lista de conversões `{ nome, data, hora, tamanho, status }`.
- Perfil: plano do usuário (`gratuito` por ora — sem paywall nesta versão).

## Design Tokens

**Fonte**: Josefin Sans (única família, usada em headings e corpo). Pesos 400/500/600/700 — títulos usam 600 (semibold), nunca bold.

**Cores**
| Papel | Hex |
|---|---|
| Fundo (claro) | `#f3f2f2` |
| Texto (claro) | `#201f1d` |
| Superfície/card (claro) | `#eae9e9` |
| Divisor | preto 16-18% opacidade |
| Accent — Marsala (base) | `#8c4a48` |
| Marsala escuro (texto sobre tint, hover) | `#582f2d` |
| Marsala claro (tint de fundo) | `#f7ece9` |
| Accent 2 — Avelã (base) | `#a9784f` |
| Avelã escuro | `#6b4830` |
| Avelã claro (tint) | `#f7efe6` |
| Fundo (escuro) | `#3a2220` (marsala profundo) |
| Superfície (escuro) | `#4a2b28` |
| Texto (escuro) | `#f3f2f2` |
| Accent em fundo escuro | `#c17f72` |

**Espaçamento**: escala base ~4.6/9.2/13.8/18.4/27.6/36.8px (múltiplos de 4.6).
**Radius**: pequeno 2px, médio 4px, grande 7px (cards/telas usam raios maiores, ~20px, como exceção de escala do app).
**Sombras**: leves — usar elevação sutil, nunca drop shadow pesado.
**Ícones**: Lucide (lucide.dev), stroke 1.5–2.5px conforme tamanho.

## Assets
Nenhuma imagem/foto usada — apenas ícones Lucide e formas geométricas (SVG) para o símbolo da marca. Nenhum asset de terceiros a licenciar.

## Files
- `DiaKit App.dc.html` — as 6 telas mobile em claro + 6 em escuro + 5 telas desktop (Home, Converter, Resultado, Histórico, Perfil), lado a lado (scroll horizontal).
- `DiaKit Logo.dc.html` — variações da marca.
- `reference-styles.css` — folha de tokens original do sistema de design (Classical) usada como base antes das customizações de fonte/cor acima; útil para conferir a escala de espaçamento/radius/sombra completa.
