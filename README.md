# Tedros Environment

## Introdução
Este repositório contém toda a infraestrutura e configurações necessárias para rodar o ambiente do Tedros utilizando Docker (incluindo serviços como Nginx, instâncias do TomEE, MongoDB, banco de dados H2 e Redis). 

## Boas Práticas de Estrutura de Diretórios
Para garantir que o fluxo de build funcione de maneira automatizada e integrada, a melhor prática é manter os três repositórios principais do ecossistema Tedros nivelados em um mesmo diretório base. Sua estrutura de pastas deve ficar exatamente desta forma:

```text
/Seu_Diretorio_De_Projetos/
  ├── Tedros/
  ├── tedros-apps/
  └── tedros-environment/
```

**Por que isso é importante?**
Ao adotar esta estrutura no mesmo nível, o fluxo foi projetado de forma que, quando você compilar os módulos do tipo **EAR** dos repositórios `Tedros` e `tedros-apps` usando o Maven, o build copiará automaticamente os artefatos `.ear` gerados diretamente para dentro da pasta local `tedros-environment/docker/deployment_app`. Assim, o seu ambiente Docker em execução (TomEE) fará o deploy da última versão do seu código instantaneamente, eliminando a necessidade de cópias manuais de arquivos.

---

## Configuração do Ambiente Local

### 1. Configurando o arquivo `hosts`
Para que os domínios locais sejam roteados corretamente para os contêineres Docker, você precisará adicionar as seguintes linhas ao seu arquivo `hosts` do Windows.

Abra o arquivo como **Administrador** no caminho `C:\Windows\System32\drivers\etc\hosts` e adicione:

```text
127.0.0.1       tedros.test
127.0.0.1       www.tedros.test
127.0.0.1       h2db.tedros.test
```

### 2. Geração de Certificados SSL e configuração do JDK (Cacerts)
Para que os serviços (como Nginx e o MongoDB 8.0) iniciem corretamente e sua aplicação local confie na conexão, é obrigatório gerar os certificados TLS/SSL locais antes de subir os contêineres.

**Passo a passo:**
1. Instale o **mkcert** na sua máquina (ex: via Chocolatey com `choco install mkcert`).
2. Abra o terminal (PowerShell) como **Administrador** e navegue até a pasta de certificados:
   ```powershell
   cd d:\GitHub\Tedros-Box\tedros-environment\docker\nginx\ssl_local
   ```
3. Instale a Autoridade Certificadora (CA) local no seu sistema:
   ```powershell
   mkcert -install
   ```
4. Gere os arquivos de certificado para os domínios locais:
   ```powershell
   mkcert tedros.test localhost 127.0.0.1 ::1 mongodb
   ```
5. Crie o certificado unificado exigido pelo MongoDB:
   ```powershell
   Get-Content tedros.test+4.pem, tedros.test+4-key.pem | Set-Content mongodb.pem
   ```
6. Copie a CA Root do mkcert para a pasta atual (para ser mapeada no contêiner):
   ```powershell
   $caPath = mkcert -CAROOT
   Copy-Item "$caPath\rootCA.pem" -Destination .\rootCA.pem
   ```
7. **Importe a CA raiz no cacerts do seu JDK** (necessário para o cliente JavaFX não tomar `Connection refused` ou falha de SSL):
   *Substitua os caminhos do Java abaixo pelos da sua máquina:*
   ```powershell
   $keytool = "C:\Program Files\Java\jdk-17\bin\keytool.exe"
   $cacerts = "C:\Program Files\Java\jdk-17\lib\security\cacerts"
   $caFile = ".\rootCA.pem"

   & $keytool -import -trustcacerts -keystore $cacerts -storepass changeit -alias mkcert-local -file $caFile -noprompt
   ```

*Nota: Agora você pode rodar o `docker-compose up -d` da pasta raiz do docker de forma segura.*

### 3. Apontando o Cliente Tedros para o Contêiner
Depois que os contêineres estiverem no ar sem erros, abra o cliente local do Tedros (JavaFX).

1. Na tela de login, clique na aba **Configuração**.
2. No campo **URL do provedor**, coloque: `https://{0}/tomee/ejb`
3. No campo **Ip do servidor**, coloque: `tedros.test`
4. Pressione enter dentro do campo Ip do servidor, ou dentro do campo url do servidor para salvar e teste o login.

### 4. Instalação do Inno Setup 5 (Requisito para Empacotamento)
Para que o `jpackage` consiga gerar com sucesso o instalador nativo (`.exe`) do cliente Tedros Desktop para Windows, é estritamente necessário ter o Inno Setup 5 instalado no ambiente local.
1. Baixe o instalador oficial do Inno Setup 5.5.9 pelo link: [https://files.jrsoftware.org/is/5/innosetup-5.5.9.exe](https://files.jrsoftware.org/is/5/innosetup-5.5.9.exe)
2. Execute o arquivo baixado e conclua a instalação utilizando as opções padrão.
3. Se necessário, reinicie o seu terminal ou computador para que as ferramentas de build reconheçam o Inno Setup no sistema.
---

## Configuração de Remote Debug
O ambiente Docker já está previamente configurado no `docker-compose.yml` para expor o modo de depuração remoto do Java (JPDA).

Estão disponíveis as seguintes portas:
* **tomee1**: Porta `8000`
* **tomee2**: Porta `8001`

### No Eclipse:
1. Vá no menu `Run > Debug Configurations...`
2. No painel à esquerda, clique com o botão direito em **Remote Java Application** e selecione `New Configuration`.
3. Escolha o projeto ejb correto que deseja debugar (ex: módulo tedros-core-ejb).
4. Na aba **Connect**, preencha:
   * **Host**: `localhost`
   * **Port**: `8000` (se quiser plugar no tomee1) ou `8001` (para plugar no tomee2).
5. Clique em **Debug**. Você verá os breakpoints ativarem.

### No IntelliJ IDEA:
1. Vá no menu `Run > Edit Configurations...`
2. Clique no botão de `+` (Add New Configuration) e escolha a opção **Remote JVM Debug**.
3. Dê um nome identificador (ex: `Tedros Remote - TomEE 1`).
4. Preencha os detalhes da configuração:
   * **Host**: `localhost`
   * **Port**: `8000` (tomee1) ou `8001` (tomee2).
   * **Use module classpath**: Selecione o módulo/projeto correspondente.
5. Deixe os outros argumentos padrão, aplique as mudanças e clique no ícone de inseto (Debug) para iniciar a sessão.

---

## Projetos e Sub-pastas do Ambiente

Abaixo detalhamos a finalidade de cada projeto e sub-pasta contidos neste repositório, junto aos guias práticos (*How-to*) para não haver erros no desenvolvimento.

### `docker`
**Finalidade:**
Fornecer a infraestrutura em contêineres para executar o ambiente Tedros completo (Nginx, instâncias do TomEE, MongoDB, Redis e banco de dados H2) em uma rede isolada, utilizando o `docker-compose`.

**How-to:**
Para que o desenvolvedor suba o contêiner sem enfrentar os erros comuns de *crash* nos serviços (ex: "Connection refused"):
1. Garanta que o serviço Docker (como o Docker Desktop) está ligado e rodando.
2. Certifique-se de que configurou o arquivo `hosts` do Windows conforme a seção principal.
3. **MUITO IMPORTANTE:** Siga todo o processo de geração dos certificados TLS com o `mkcert` dentro de `nginx/ssl_local`, além de copiar o `rootCA.pem`. Sem isso, o contêiner do MongoDB e o proxy reverso Nginx não conseguirão escutar a porta 443 e reiniciarão sem parar.
4. Caso precise inicializar o H2 com dados locais, execute o script do `startup-database` previamente.
5. Navegue pelo terminal (PowerShell) para a pasta `docker` e inicie o ambiente:
   ```bash
   docker-compose up -d
   ```
6. Opcionalmente, acompanhe a saúde dos contêineres com `docker-compose logs -f`.

---

### `openjfx-sdk`
**Finalidade:**
Disponibilizar os binários base e arquivos nativos (DLLs) do SDK do JavaFX diretamente no repositório. Isso garante que a aplicação Desktop possa ser empacotada e executada por qualquer desenvolvedor a partir dos scripts sem precisar buscar o SDK ou configurar caminhos absolutos.

---

### `server-application`
**Finalidade:**
Subir o servidor TomEE utilizando o repositório Maven local através do plugin *Cargo*. Ele fará o deploy automático dos `.ear` compilados (instalados) pelas pastas dos repositórios do código fonte (ex: via `mvn install`).

**How-to:**
Para subir o servidor via plugin *Cargo*, não é necessário interagir com o Docker.
No terminal, dentro da pasta do projeto `server-application`:
1. **Rode para iniciar o servidor:** `mvn cargo:run`
2. **Rode para parar o servidor:** `mvn cargo:stop`
3. **No cliente do Tedros**, ajuste a configuração para apontar para o Cargo:
   * **URL do provedor:** `http://{0}:8081/tomee/ejb` (Note a porta 8081 em HTTP).
   * **IP do servidor:** `127.0.0.1`

**Como adicionar um novo EAR ou WAR ao servidor (Deploy pelo Cargo):**
Se você quiser que o TomEE suba um módulo novo:
1. Primeiro, você **precisa compilar e instalar** o projeto desejado rodando `mvn clean install` na pasta original dele (para ele ficar salvo no repositório `~/.m2` da sua máquina).
2. Abra o arquivo `server-application/pom.xml`.
3. Na seção `<dependencies>`, importe o novo módulo adicionando-o na lista:
   ```xml
   <dependency>
       <groupId>org.tedros</groupId>
       <artifactId>seu-novo-projeto-ejb-ear</artifactId>
       <version>1.0-SNAPSHOT</version>
       <type>ear</type>
   </dependency>
   ```
4. Ainda no `pom.xml`, desça até a configuração do plugin `<artifactId>cargo-maven3-plugin</artifactId>`. Dentro da tag `<deployables>`, declare esse novo pacote:
   ```xml
   <deployable>
       <groupId>org.tedros</groupId>
       <artifactId>seu-novo-projeto-ejb-ear</artifactId>
       <type>ear</type>
   </deployable>
   ```
5. Agora rode `mvn cargo:run` e o novo pacote será injetado no deploy.

---

### `server-chat`
**Finalidade:**
`<DEPRECIADO>`

---

### `startup-database`
**Finalidade:**
Criar a infraestrutura de pastas locais de sistema e subir os arquivos base para o banco de dados local.

**How-to:**
O desenvolvedor precisa certificar-se de que a estrutura `~/.tedrosData/h2` exista junto com o arquivo de banco.
1. Abra o PowerShell e navegue até a pasta `startup-database`.
2. Para que todo o processo funcione de forma automática, criamos um script para Windows:
   ```powershell
   .\create-tedros-data.ps1
   ```
   *Este script varre a sua pasta de usuário (home), cria o diretório `h2` necessário e faz a cópia do `init.sql` se ele não existir.*

---

### `startup-tedros-box`
**Finalidade:**
Subir e empacotar o cliente Desktop do sistema Tedros Box em modo nativo para ser depurado ou gerar um pacote executável (instalador) para Windows usando o utilitário nativo (JPackage).

**How-to:**
Para utilizar e subir a aplicação com sucesso, observe as seguintes diretrizes:

**1. Gerando o executável de instalação nativo (.exe)**
Se o objetivo é gerar o executável final:
1. No PowerShell, acesse o diretório do `startup-tedros-box`.
2. O script de geração do JPackage requer o JAR original construído. Assim, primeiro compile o projeto rodando `mvn clean package`.
3. Após isso, chame o script em PowerShell que faz a geração apontando pro openjfx nativo local:
   ```powershell
   .\package.ps1
   ```
4. Se rodar com sucesso, ele irá gerar o instalador compilado dentro de uma nova pasta `packages`.

**2. Rodando e testando na IDE**
Para testar dentro da sua IDE e não receber crashes repentinos de System.out/buffer:
A classe que deve ser iniciada é a **`com.tedros.TedrosLauncher`** (e **NÃO** diretamente a `com.tedros.Main`). 

*A `TedrosLauncher` age como uma blindagem protetora.* 
Se a IDE sobrecarregar o renderizador do console (`System.out`), o sistema de logging do Tedros (Logback) e o Console interno da JVM podem conflitar gerando prints duplicados ou travas do sistema Windows (buffer IO). A `TedrosLauncher` silencia a saída padrão e empurra todos os erros não processados ou logs de crash violentos (System.err) de maneira controlada para o diretório de dados em: `C:\Users\SEU_USUARIO\.tedros\LOG\tedros_crash.log`. Após isso ser feito em segurança, ela chama de fato a janela visual através do `Main.main(args)`.

> **Dica para Desenvolvedores:** Caso precise visualizar os logs normais no console da IDE (Eclipse/IntelliJ) durante a execução local, adicione o argumento da VM `-Dtedros.dev=true` nas configurações de execução (*Run Configurations*) do `TedrosLauncher`. Isso reativará a saída padrão.