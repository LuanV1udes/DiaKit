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

O app conversa com o backend por HTTP (endereço configurável em *Perfil › Servidor de conversão*) — normalmente o próprio aparelho, mas pode ser outra máquina na mesma rede local. O backend nunca fala com a internet: ele só chama o binário do LibreOffice instalado na máquina (ou uma cópia portátil baixada por `backend/scripts/fetch-libreoffice.ps1`) e devolve o resultado.

## Como rodar localmente

**Backend**
```bash
cd backend
npm install
npm run fetch-libreoffice   # baixa uma cópia portátil do LibreOffice (~1,5GB), ou defina SOFFICE_PATH com uma instalação já existente
npm start                   # sobe em http://localhost:4123
```

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
