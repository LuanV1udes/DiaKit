**Português** | [English](README.en.md)

# DiaKit

Ferramentas essenciais do dia a dia para documentos — direto do seu aparelho, sem depender de servidores de terceiros.

## O que é

DiaKit é um app multiplataforma (Android, iOS, Windows, macOS, Linux e Web) que reúne pequenas tarefas do dia a dia com documentos que hoje exigem abrir vários sites ou programas diferentes. A primeira e principal ferramenta é converter Word, Excel e PowerPoint em PDF pronto para impressão.

**Já funciona:**
- Word / Excel / PowerPoint (`.doc`, `.docx`, `.xls`, `.xlsx`, `.ppt`, `.pptx`) → PDF
- PDF → Imagens
- CSV ↔ Excel

**Planejado:**
- PDF → Word
- Comprimir PDF
- Assinar PDF

## Como funciona

DiaKit tem duas partes que rodam localmente, sem enviar seus arquivos para a nuvem:

```
app/       Flutter — a interface (mobile, desktop e web)
backend/   Node.js/Express — recebe o arquivo e chama o LibreOffice
           em modo headless para fazer a conversão de verdade
```

O app conversa com o backend por HTTP (endereço configurável em *Perfil › Servidor de conversão*) — normalmente o próprio aparelho, mas pode ser outra máquina na mesma rede local. O backend nunca fala com a internet: ele só chama o binário do LibreOffice instalado na máquina (ou uma cópia portátil baixada no Windows) e devolve o resultado.

## Como rodar localmente

**Backend**
```bash
cd backend
npm install
npm run fetch-libreoffice   # Windows: baixa uma copia portatil do LibreOffice (~1,5GB). Linux/macOS: detecta o gerenciador de pacotes e mostra o comando de instalacao
npm start                   # sobe em http://localhost:4123
```

`fetch-libreoffice` detecta o sistema operacional automaticamente: no Windows ele baixa e extrai uma cópia portátil (não há gerenciador de pacotes padrão por lá); no Linux e macOS ele só verifica se o `soffice` já está disponível e, se não estiver, indica o comando certo para a sua distro (`apt`, `dnf`, `pacman`, `zypper`) ou o Homebrew. Em qualquer plataforma dá pra pular isso e apontar direto pra uma instalação existente com a variável `SOFFICE_PATH`.

**App**
```bash
cd app
flutter pub get
flutter run
```

## Como o projeto vai evoluir

O roadmap segue a lista de ferramentas "planejadas" acima — cada uma vira uma nova tela no app e uma nova rota no backend, seguindo o mesmo padrão das já existentes (`backend/src/routes/convert.js`). Sugestões, relatos de bug e PRs são bem-vindos via Issues/Pull Requests.

## Licença

Este projeto é distribuído sob a [PolyForm Noncommercial License 1.0.0](LICENSE): você pode usar, estudar, modificar e distribuir o código livremente para fins **não comerciais**. Uso comercial (venda, revenda, oferecer como serviço pago, embutir em produto pago) exige uma licença separada — abra uma [issue](../../issues) para conversar sobre isso.
