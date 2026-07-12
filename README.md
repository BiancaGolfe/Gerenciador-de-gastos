# Poup

Poup é um aplicativo desenvolvido em Flutter para ajudar no controle financeiro pessoal de forma prática, visual e offline. A proposta é permitir que o usuário registre despesas, acompanhe o que foi gasto por mês, visualize gráficos, organize categorias e acompanhe metas financeiras, tudo sem depender de um servidor externo.

Desenvolvido por Bianca Gabriela Golfe, Laura Leandra Faccin e Filipe Casadei.

### Requisitos mínimos

- Flutter SDK 3.x ou superior
- Dart compatível com o SDK do Flutter
- Git
- Android Studio para emulador Android, ou dispositivo físico
- Chrome para execução web, se desejado

## Resumo do projeto

Este aplicativo foi pensado para ser uma ferramenta simples e funcional para quem deseja organizar finanças do dia a dia. Ele permite:

- cadastrar gastos com valor, categoria, descrição e data;
- anexar comprovantes por câmera ou galeria;
- visualizar um resumo mensal do que foi gasto;
- filtrar despesas por categoria no histórico;
- analisar o comportamento dos gastos por meio de gráficos;
- criar categorias personalizadas;
- definir um limite mensal de gastos;
- usar o app em modo offline, com dados salvos localmente.

## O que o aplicativo faz

Ao abrir o app, o usuário pode:

1. criar uma conta ou fazer login;
2. registrar novos gastos;
3. escolher uma categoria para cada despesa;
4. adicionar uma foto do comprovante;
5. acompanhar o total gasto no mês atual;
6. navegar pelo histórico e pelos gráficos;
7. criar metas e receber um acompanhamento visual do limite definido.

## Como o aplicativo funciona

### 1. Tela de login e cadastro

Na abertura, o app direciona o usuário para uma tela de autenticação. Ali é possível:

- fazer login com e-mail e senha;
- criar uma nova conta;
- manter a sessão ativa no dispositivo.

### 2. Tela inicial

Na tela inicial, o usuário encontra:

- um resumo do mês atual;
- o total gasto até o momento;
- a meta de gastos, quando definida;
- uma visão rápida dos gastos mais recentes.

Também é possível trocar o mês visualizado e alternar entre tema claro e escuro.

### 3. Cadastro de gastos

Ao criar ou editar um gasto, o app solicita:

- valor;
- categoria;
- descrição opcional;
- data;
- imagem de comprovante (opcional).

A tela permite também criar novas categorias diretamente no fluxo de cadastro.

### 4. Histórico

Na área de histórico, o usuário consegue:

- visualizar todos os gastos do mês selecionado;
- filtrar por categoria;
- abrir o detalhe de cada gasto;
- editar ou excluir registros.

### 5. Gráficos

A seção de gráficos apresenta uma análise visual por categoria, tanto para o mês corrente quanto para o ano. Isso ajuda a entender para onde o dinheiro está indo.

### 6. Categorias

O usuário pode criar, editar e remover categorias personalizadas, além de usar categorias padrão já existentes no app.

### 7. Limite e notificações

O aplicativo também suporta a definição de um limite mensal de gastos. Quando o valor gasto se aproxima ou ultrapassa esse limite, o sistema pode gerar uma avaliação visual e, dependendo da configuração do ambiente, notificações relacionadas.

## Tecnologias utilizadas

Este projeto utiliza as seguintes tecnologias e bibliotecas:

- Flutter e Dart
- SQLite local via sqflite
- Armazenamento local para web via shared_preferences
- image_picker para câmera e galeria
- fl_chart para gráficos
- intl para formatação de data e moeda em português
- flutter_local_notifications para notificações
- emoji_picker_flutter e flutter_colorpicker para seleção visual de categorias

## Como executar o projeto passo a passo

### 1. Clonar o repositório

No terminal do VS code, execute:

```bash
git clone https://github.com/seu-usuario/Gerenciador-de-gastos.git
cd Gerenciador-de-gastos
```

### 2. Verificar se o Flutter está instalado

Execute:

```bash
flutter --version
flutter doctor
```

Se o Flutter não estiver configurado corretamente, siga as instruções exibidas no comando `flutter doctor` antes de continuar.

### 3. Instalar as dependências

Na pasta do projeto, rode:

```bash
flutter pub get
```

Esse comando baixa todas as bibliotecas utilizadas pelo aplicativo.

### 4. Executar no dispositivo ou emulador

Para rodar no ambiente Android ou iOS:

```bash
flutter run
```

Se houver mais de um dispositivo disponível, o Flutter vai perguntar qual usar. Você também pode escolher um dispositivo específico:

```bash
flutter run -d <device-id>
```

### 5. Executar em navegador

Para testar a versão web:

```bash
flutter run -d chrome
```

## Observações importantes

- O aplicativo funciona de forma local e offline.
- Os dados são salvos no dispositivo, então não há sincronização com servidor ou nuvem.
- Na versão web, os dados ficam armazenados no navegador do usuário.
- Para usar a câmera e a galeria, é necessário conceder permissão no sistema operacional.
- O projeto foi pensado para uso pessoal e simples, com foco em organização financeira diária.


## Conclusão

O Poup é uma solução prática para quem quer organizar as finanças pessoais com facilidade, sem depender de ferramentas complexas. Ele combina simplicidade, interface moderna e recursos úteis para acompanhar despesas de forma visual e objetiva.
