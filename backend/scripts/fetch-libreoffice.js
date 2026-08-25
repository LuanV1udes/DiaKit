#!/usr/bin/env node
'use strict';

// Dispatcher multiplataforma para `npm run fetch-libreoffice`.
//
// Windows: baixa e extrai uma copia portatil do LibreOffice (delega para
// fetch-libreoffice.ps1) -- e a unica forma de rodar sem exigir instalacao,
// ja que o Windows nao tem um gerenciador de pacotes padrao.
//
// Linux/macOS: essas plataformas ja tem um jeito nativo e leve de instalar
// (apt/dnf/pacman/brew), entao em vez de embutir uma copia portatil so
// detectamos o gerenciador de pacotes disponivel e mostramos o comando certo.

const path = require('path');
const { execFileSync, spawnSync } = require('child_process');

const PACKAGE_MANAGERS = [
  { bin: 'apt-get', install: 'sudo apt install libreoffice' },
  { bin: 'dnf', install: 'sudo dnf install libreoffice' },
  { bin: 'pacman', install: 'sudo pacman -S libreoffice-fresh' },
  { bin: 'zypper', install: 'sudo zypper install libreoffice' },
  { bin: 'apk', install: 'sudo apk add libreoffice' },
];

function isOnPath(command) {
  try {
    const finder = process.platform === 'win32' ? 'where' : 'which';
    execFileSync(finder, [command], { stdio: 'ignore' });
    return true;
  } catch {
    return false;
  }
}

function runWindows() {
  const scriptPath = path.join(__dirname, 'fetch-libreoffice.ps1');
  const result = spawnSync('powershell', ['-ExecutionPolicy', 'Bypass', '-File', scriptPath], {
    stdio: 'inherit',
  });
  process.exit(result.status ?? 1);
}

function runUnix() {
  if (isOnPath('soffice')) {
    console.log('LibreOffice ja esta disponivel no PATH (soffice) -- nada a fazer.');
    return;
  }

  const manager = PACKAGE_MANAGERS.find((pm) => isOnPath(pm.bin));
  if (manager) {
    console.log(
      `LibreOffice nao encontrado. Instale com o gerenciador de pacotes da sua distro:\n\n  ${manager.install}\n`
    );
  } else if (process.platform === 'darwin') {
    console.log(
      'LibreOffice nao encontrado. Instale com o Homebrew:\n\n'
      + '  brew install --cask libreoffice\n\n'
      + 'ou baixe em https://www.libreoffice.org/download/'
    );
  } else {
    console.log(
      'LibreOffice nao encontrado e nao foi possivel detectar o gerenciador de pacotes.\n'
      + 'Instale o LibreOffice pelo gerenciador da sua distro, ou baixe em https://www.libreoffice.org/download/\n'
      + 'Se o soffice ficar em um local fora do PATH, defina SOFFICE_PATH apontando pra ele.'
    );
  }
}

if (process.platform === 'win32') {
  runWindows();
} else {
  runUnix();
}
