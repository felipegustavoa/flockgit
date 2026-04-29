# FlockGit

FlockGit e uma CLI open source para desenvolvedores que trabalham com varios repositorios Git.
Veja status, troque branches e atualize projetos pelo terminal, sem entrar pasta por pasta.

O comando principal da ferramenta e `flockgit`.
Tambem existe o atalho curto `fg`.

## English

FlockGit is an open source CLI for developers who work with multiple Git repositories.
Check status, switch branches, and update projects from one terminal.

## Status

Versao atual: `0.9.0-beta.1`

Esta e uma beta publica.

Suporte atual:
- macOS
- Linux
- `zsh`
- `bash`

## O que a ferramenta faz

- lista a branch atual de todos os repositorios mapeados
- destaca repositorios com alteracoes locais
- mostra estado de sincronizacao com upstream quando existir
- troca branch em varios repositorios com um unico comando
- tenta encontrar a branch localmente e, se necessario, no remoto configurado
- atualiza a branch atual usando o upstream real do repositorio
- mostra um resumo opcional no final com `--summary`

## Instalacao

Na raiz do projeto:

```bash
chmod +x ./install.sh
./install.sh
```

O instalador:
- copia o projeto para `~/.flockgit`
- cria um `config` inicial com um exemplo comentado
- preserva o arquivo `config` em reinstalacoes
- adiciona `source "~/.flockgit/aliases.sh"` no `~/.zshrc` ou `~/.bashrc`

Depois da instalacao:

- abra um novo terminal e rode `flockgit -h`
- ou use o atalho `fg -h`
- ou recarregue o shell manualmente

Exemplo:

```bash
source ~/.zshrc
flockgit -h
```

Se voce usa `bash`:

```bash
source ~/.bashrc
flockgit -h
```

Antes do primeiro `flockgit status`, edite o arquivo `~/.flockgit/config` e adicione seus repositorios.
## Atualizacao

Se voce estiver com a versao mais recente do projeto:

```bash
./install.sh
```

O mesmo instalador e usado para instalar e atualizar.

Se `~/.flockgit` ja existir, o instalador entra em modo de atualizacao:
- substitui os scripts pela versao nova
- preserva o `config` existente
- nao duplica o bloco no `~/.zshrc` ou `~/.bashrc`
- informa explicitamente que esta atualizando a instalacao atual

Fluxo recomendado para atualizar:

```bash
cd pasta-da-nova-versao
./install.sh
```

Se a instalacao atual ja existir em `~/.flockgit`, o instalador vai entrar automaticamente em modo de atualizacao.

## Desinstalacao

```bash
~/.flockgit/uninstall.sh
```

O desinstalador:
- remove `~/.flockgit`
- remove o bloco adicionado no `~/.zshrc` e `~/.bashrc`

## Uso

```bash
flockgit -h
flockgit status
flockgit status --summary
flockgit update
flockgit update --summary
flockgit change main
flockgit change nome-da-branch
flockgit change nome-da-branch --summary

fg -h
fg status
fg update
fg change main
```

Fluxo basico de uso:

1. instale com `./install.sh`
2. abra um novo terminal ou recarregue o shell
3. edite `~/.flockgit/config`
4. rode `flockgit status`

Autocomplete:
- `flockgit <TAB>` sugere `status`, `update`, `change`, `-h` e `--help`
- `fg <TAB>` sugere `status`, `update`, `change`, `-h` e `--help`
- `flockgit status <TAB>` sugere `--summary`
- `flockgit update <TAB>` sugere `--summary`
- `flockgit change <TAB>` sugere branches Git e `--summary`

## Configuracao

O arquivo de configuracao fica em:

```bash
~/.flockgit/config
```

Na primeira instalacao, esse arquivo e criado como template e precisa ser editado antes do primeiro `flockgit status`.

Formato basico:

```bash
dir=/caminho/do/projeto base=main
dir=/outro/projeto base=master
```

Tambem aceita valores entre aspas:

```bash
dir="/caminho/com espacos/projeto" base=main
```

Exemplo inicial:

```bash
dir=/Users/voce/projeto-a base=main
dir=/Users/voce/projeto-b base=master
```

Exemplo com caminho contendo espacos:

```bash
dir="/Users/voce/Meu Projeto/projeto-a" base=main
```

Regras atuais:
- linhas vazias sao ignoradas
- comentarios iniciados por `#` sao ignorados
- diretorios inexistentes sao ignorados
- diretorios que nao sao repositorios Git sao ignorados
- linhas invalidas sao reportadas em `stderr`

Se o arquivo ainda estiver sem repositorios validos, a CLI mostra uma mensagem com exemplos do formato esperado.

## Resumo opcional

Quando voce usa `--summary`, a ferramenta mostra ao final:

- repositorios processados
- repositorios ignorados
- falhas Git encontradas

Exemplos:

```bash
flockgit status --summary
flockgit update --summary
flockgit change main --summary
```

## Comportamentos importantes

- `flockgit status` mostra branch atual, dirty, ahead, behind e `no-remote` quando aplicavel
- `flockgit update` usa o upstream configurado da branch atual; nao assume `origin`
- `flockgit change` tenta branch local primeiro; se nao existir, tenta localizar no remoto configurado
- se a branch pedida nao existir, o comportamento atual e manter a branch atual e apenas mostrar o status do repositorio
- falhas de `pull`, `fetch` e `switch` sao reportadas por repositorio e propagadas no exit code final

## Testes

Para rodar a suite:

```bash
bash tests/run.sh
```

Para rodar so uma parte:

```bash
bash tests/test_cli.sh
bash tests/test_install.sh
```

Todos os testes rodam em diretorios temporarios e nao usam seus repositorios reais.

## Beta

Esta beta ja cobre o fluxo principal da ferramenta, mas ainda esta aberta a refinamentos em:

- UX do terminal
- comportamento de autocomplete em ambientes diferentes
- instalacao em setups variados de shell
- feedback de uso real em multi-repo

## Autor

Criado e mantido por Felipe Gustavo Andrzejewski.

- GitHub: [felipegustavoa](https://github.com/felipegustavoa)
- LinkedIn: [Felipe Gustavo Andrzejewski](https://www.linkedin.com/in/felipe-gustavo-andrzejewski-9baa2a16/)

## Licenca

Este projeto esta licenciado sob a GNU GPL v2.0 ou posterior (`GPL-2.0-or-later`).

O arquivo [LICENSE](/Users/felipe/www/branches/branches-v3/LICENSE) inclui o texto completo da GPL v2 junto com o aviso de aplicacao do projeto em modo `or later`.

## Changelog

Veja [CHANGELOG.md](/Users/felipe/www/branches/branches-v3/CHANGELOG.md).
