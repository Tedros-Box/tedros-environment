# Tedros Environment

## Introdução
Este repositório contém toda a infraestrutura e configurações necessárias para rodar o ambiente do Tedros utilizando Docker (incluindo serviços como Nginx, instâncias do TomEE, MongoDB, PostgreSQL ou H2 e Redis). Inclui também, em compose separado, a stack de observabilidade (Prometheus + Grafana + Alertmanager) do **Tool Relay** — o serviço de IA centralizado no backend — com dashboards de tokens, custo em USD, tools, latência do LLM e saúde do relay (ver [`docker/observability`](#dockerobservability) abaixo).

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
Fornecer a infraestrutura em contêineres para executar o ambiente Tedros completo (Nginx, instâncias do TomEE, MongoDB, Redis e banco de dados PostgreSQL ou H2) em uma rede isolada, utilizando o `docker-compose`. A subpasta `observability/` complementa este compose com um stack **separado** (Prometheus + Grafana + Alertmanager) para monitorar o Tool Relay de IA — ver [`docker/observability`](#dockerobservability).

**How-to:**
Para que o desenvolvedor suba o contêiner sem enfrentar os erros comuns de *crash* nos serviços (ex: "Connection refused"):
1. Garanta que o serviço Docker (como o Docker Desktop) está ligado e rodando.
2. Certifique-se de que configurou o arquivo `hosts` do Windows (conforme a seção principal). Abra o arquivo como **Administrador** no caminho `C:\Windows\System32\drivers\etc\hosts` e adicione o seguinte conteúdo:
   ```text
   127.0.0.1       tedros.test
   127.0.0.1       www.tedros.test
   127.0.0.1       h2db.tedros.test
   ```
3. **MUITO IMPORTANTE:** Siga todo o processo de geração dos certificados TLS com o `mkcert` dentro de `nginx/ssl_local`, além de copiar o `rootCA.pem`. Sem isso, o contêiner do MongoDB e o proxy reverso Nginx não conseguirão escutar a porta 443 e reiniciarão sem parar.
4. Caso precise inicializar o banco com dados locais, execute o script do `startup-database` previamente.
5. Navegue pelo terminal (PowerShell) para a pasta `docker` e inicie o ambiente utilizando o profile do banco desejado (PostgreSQL é o padrão recomendado):
   
   **Para rodar o ambiente com PostgreSQL:**
   Primeiro, crie um arquivo chamado `.env.postgres` na pasta `docker` com as credenciais (não versione este arquivo):
   ```env
   # Feature flag: valores TEDROS_DB_* para rodar o stack de producao com PostgreSQL.
   # Uso: docker compose --profile postgres --env-file .env.postgres up -d
   # ATENCAO: contem senha — restrinja a leitura (chmod 600 .env.postgres) e nao versione.
   # NOTA: $ literal precisa ser escrito como $$ (o compose interpola $VAR em env files).
   TEDROS_DB_DRIVER=org.postgresql.Driver
   TEDROS_DB_URL=jdbc:postgresql://postgres:5432/tedros
   TEDROS_DB_USER=tdrs
   TEDROS_DB_PASSWORD=<SENHA FORTE>
   ```
   Depois, inicie os contêineres:
   ```bash
   docker-compose --profile postgres --env-file .env.postgres up -d --build
   ```
   
   **Para rodar o ambiente com H2 (exemplo):**
   ```bash
   docker-compose --profile h2 up -d --build
   ```
6. Opcionalmente, acompanhe a saúde dos contêineres com `docker-compose logs -f`.

---

### `docker/observability`
**Finalidade:**
Stack de observabilidade do **Tool Relay** (o serviço de IA centralizado no backend, módulo `tdrs-ai` do repositório `Tedros`): Prometheus (métricas), Grafana (dashboards) e Alertmanager (alertas). Fica em um `docker-compose` **separado** do principal (`docker-compose.observability.yml`) de propósito — em produção essa stack pode rodar em outra máquina, bastando trocar os alvos de scrape no `prometheus.yml`, sem tocar no compose da aplicação.

> **Nota:** essa stack é opcional para rodar o Tedros — sem ela a aplicação funciona normalmente, você só perde os dashboards/alertas do consumo de IA.

**Pré-requisito de rede:** o compose principal (`docker-compose.yml`) já declara a rede com nome fixo `tedros-net`; o compose de observabilidade se anexa a ela como rede `external`. Por isso, **suba primeiro o ambiente principal** e só depois a observabilidade.

**How-to (dev, mesma máquina):**
```bash
cd tedros-environment/docker
docker compose --profile postgres --env-file .env.postgres up -d   # ambiente principal primeiro
docker compose -f docker-compose.observability.yml up -d           # depois, a stack de observabilidade
```

**Variáveis de ambiente:**

| Variável | Default | Onde é usada |
|---|---|---|
| `GF_ADMIN_USER` | `admin` | Usuário admin do Grafana |
| `GF_ADMIN_PASSWORD` | `admin` | Senha admin do Grafana — **troque em produção** |
| `TEDROS_DB_PASSWORD` | `xpto` | Senha do datasource Postgres do Grafana (mesma do banco principal, ver `.env.postgres`) |
| `TEDROS_NODE_NAME` | `tomee1` / `tomee2` | Já definida no `docker-compose.yml` principal por nó — vira o label `node` em todas as métricas Prometheus do Tool Relay, permitindo distinguir os dois nós do cluster |

**Endpoints depois de subir:**
- Prometheus: `http://localhost:9090`
- Grafana: `http://localhost:3000` (login `admin`/`admin` por padrão, pasta **"Tedros AI"**)
- Alertmanager: `http://localhost:9093`

**De onde vêm as métricas:** cada nó TomEE expõe o Tool Relay em `tomeeN:8081/ai/prometheus` (porta HTTP interna 8081, **não** 8080; e o path é `/ai/prometheus`, não `/ai/metrics` — o TomEE Plume já reserva `<contexto>/metrics` para o MicroProfile Metrics). O Prometheus (`observability/prometheus/prometheus.yml`) raspa os dois nós a cada 15s. Liveness/readiness do módulo de IA fica em `/ai/status` (MicroProfile Health).

> **Atenção — segurança:** `/ai/*` nunca é roteado pelo Nginx para fora (bloqueio explícito com `return 403;` em `nginx/conf.d.local/tedros.conf`, defesa em profundidade). O Prometheus só alcança os endpoints por dentro da rede Docker.

**Dashboards provisionados** (`observability/grafana/dashboards/`, pasta "Tedros AI" no Grafana):

| Arquivo | Dashboard | Conteúdo |
|---|---|---|
| `01-tokens-custo.json` | Tedros AI — Tokens & Custo | Tokens/min por provider, split input/output, acumulado 24h |
| `02-tools.json` | Tedros AI — Tools | Top-N tools mais usadas, taxa de erro por tool, latência |
| `03-latencia-llm.json` | Tedros AI — Latência LLM | p50/p95/p99 por provider e modelo, throughput de turnos |
| `04-saude-relay.json` | Tedros AI — Saúde do Relay | Conversas ativas vs. cap, evictions, pending turns, heap/GC/threads, uptime, profundidade do turno |
| `05-consumo-usuario.json` | Tedros AI — Consumo por Usuário | Top consumidores de tokens, tools por usuário (datasource Postgres) |
| `06-custo-llm.json` | Tedros AI — Custo LLM | Custo em USD por provider/modelo/tier/usuário, cache-hit rate, custo diário, US$/h em tempo real |

> **Atenção:** os painéis de `05-consumo-usuario.json` e a maior parte de `06-custo-llm.json` leem o ledger no **Postgres** (datasource `Tedros-Postgres`) — exigem `docker compose --profile postgres`. No profile `h2` esses painéis ficam vazios (o ledger vive no H2, não é consultado pelo Grafana); só o painel de US$/h (via Prometheus) continua funcionando.

**Alertas** (`observability/prometheus/rules/tedros-ai.yml`):

| Alerta | Dispara quando |
|---|---|
| `RelayLLMErrorRateHigh` | Taxa de erro `LLM_ERROR`/`INTERNAL_ERROR` > 0,1/s por 5min |
| `RelayLLMLatencyHigh` | p95 de latência do LLM > 30s por 10min |
| `RelayConversationCapNear` | Conversas ativas / `sys.ai.toolrelay.max.conversations` > 90% (risco de usuários perderem contexto por LRU) |
| `RelayMaxDepthFrequent` | Turnos batendo no limite de recursão (`MAX_DEPTH`) — possível loop de tools |
| `RelayDailySpendHigh` | Gasto de IA acumulado nas últimas 24h > US$ 50 (teto ajustável na regra) |
| `RelayPricingMissing` | Chamada ao LLM sem preço cadastrado em `TAI_PRICE` — custo subestimado |
| `RelayHeapPressure` | Heap do nó > 85% por 10min |
| `RelayNoTraffic` | Nenhum turno de IA nos últimos 15min (serviço ocioso ou fora do ar) |
| `RelayTargetDown` | Prometheus não consegue raspar um dos nós (`/ai/prometheus` inacessível) |

Depois de editar as regras, recarregue sem reiniciar o Prometheus (a stack sobe com `--web.enable-lifecycle`):
```bash
curl.exe -X POST http://localhost:9090/-/reload
```

**Configuração do Tool Relay (properties, não variáveis de ambiente):** o módulo `tdrs-ai-ejb` semeia as próprias chaves no primeiro boot do EAR (editáveis depois na UI de configurações do Tedros):

| Property | Default | Uso |
|---|---|---|
| `sys.ai.toolrelay.enabled` | `false` | Liga o modo relay (IA centralizada no backend) no cliente FE |
| `sys.ai.toolrelay.conversation.ttl.min` | `30` | TTL de eviction de conversas inativas em memória |
| `sys.ai.toolrelay.pendingturn.ttl.min` | `5` | Timeout de um turno com tool call pendente no cliente |
| `sys.ai.toolrelay.max.conversations` | `2000` | Cap global de conversas simultâneas em memória (por nó) |
| `sys.ai.toolrelay.debug` | `false` | Liga log de request/response do LLM |
| `sys.ai.usage.retention.months` | `4` | Meses de detalhe (`TAI_LLM_CALL`/`TAI_USAGE_EVENT`) antes do rollup+expurgo diário |

**Banco de dados — tabelas do custo de IA** (schema `tedros_core`, PU `tedros_core_pu`): `TAI_PRICE` (preços por provider/modelo/tier, versionado), `TAI_LLM_CALL` (ledger — 1 linha por chamada ao LLM) e `TAI_USAGE_MONTHLY` (rollup mensal, nunca expurgado). São criadas automaticamente pelo `create-tables` no boot do EAR.

> **Atenção no deploy:** `create-tables` cria tabelas novas mas **não** adiciona colunas a tabelas já existentes. Se você já tinha um deploy anterior (sem custo de tokens) e a tabela `TAI_USAGE_EVENT` já existia, rode manualmente (idempotente, mesma sintaxe em H2 e Postgres):
> ```sql
> ALTER TABLE tedros_core.tai_usage_event ADD COLUMN IF NOT EXISTS turn_id VARCHAR(60);
> ALTER TABLE tedros_core.tai_usage_event ADD COLUMN IF NOT EXISTS tokens_in_cache BIGINT;
> ALTER TABLE tedros_core.tai_usage_event ADD COLUMN IF NOT EXISTS total_cost_usd DECIMAL(12,6);
> ```
> Postgres: `docker exec -i tedros-postgres psql -U tdrs -d tedros -c "<os 3 ALTER>"`. H2: console web em `http://localhost:81` (`jdbc:h2:tcp://localhost:1521/h2/db`, usuário/senha `tdrs`/`xpto`).

> **Dica Pro — cluster de 2 nós:** `tomee1` e `tomee2` sobem juntos e ambos rodam o seed de preços (`TAI_PRICE`) de forma idempotente; existe uma pequena janela de corrida que pode gerar linhas duplicadas (preços iguais, inofensivo). Para evitar, na primeira subida suba um nó de cada vez.

**Deploy do módulo de IA (`tdrs-ai-ejb-ear`):** o EAR é assado na imagem do TomEE (o `Dockerfile` copia `deployment_app/` para `apps/`); o build Maven do `tdrs-ai` já copia o `.ear` para cá automaticamente (mesma property `docker.app.folder` usada pelos demais módulos).
```powershell
cd D:\GitHub\Tedros-Box\Tedros\tedrosbox\tdrs-ai
mvn clean package
cd D:\GitHub\Tedros-Box\tedros-environment\docker
docker compose up -d --build tomee1 tomee2
```

**Verificação:**
- `curl http://localhost:9090/-/healthy` e a UI do Prometheus em `/targets` mostrando `tedros-ai-relay` como `UP`.
- Grafana → pasta "Tedros AI" com os 6 dashboards renderizando.
- Logs do TomEE mostrando `TAI_PRICE seeded on first boot: N rows ...` sem erro de DDL.

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
1. **Rode para iniciar o servidor:** 
   - Com H2: `mvn cargo:run`
   - Com PostgreSQL: `mvn cargo:run -Pdb-postgres`
2. **Rode para parar o servidor:** `mvn cargo:stop`
3. **No cliente do Tedros**, ajuste a configuração para apontar para o Cargo:
   * **URL do provedor:** `http://{0}:8081/tomee/ejb` (Note a porta 8081 em HTTP).
   * **IP do servidor:** `127.0.0.1`

**Como adicionar um novo EAR ou WAR ao servidor (Deploy pelo Cargo):**
Se você quiser que o TomEE suba um módulo novo:
1. Primeiro, você **precisa compilar e instalar** o projeto desejado.
   
   > **Dica (Build Automatizado):** O repositório `tedros-apps` contém um script utilitário chamado `build-projects.ps1` que facilita muito esse processo, fornecendo uma interface visual (Out-GridView) que respeita e garante a ordem correta de build. Para usá-lo:
   > - Edite o arquivo `build-projects.ps1` e configure os caminhos na variável `$projects`, e o caminho do `settings.xml` do Maven (na linha do `mvn`) para refletirem os diretórios exatos da sua máquina.
   > - **Criou um novo projeto/EAR?** Lembre-se de adicioná-lo na lista de `$projects` dentro do script. É importante respeitar a ordem (se o seu projeto depende do `app-person`, ele deve estar posicionado abaixo dele na lista).
   > - Para rodar: Execute `.\build-projects.ps1` no PowerShell, selecione os projetos desejados e clique em OK.
   
   Se não quiser usar o script, basta compilar o projeto manualmente rodando `mvn clean install` na pasta original dele (para que ele fique salvo no repositório `~/.m2` da sua máquina).
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
O desenvolvedor precisa inicializar a estrutura do banco desejado (PostgreSQL ou H2).
1. Abra o PowerShell e navegue até a pasta `startup-database`.
2. Para que todo o processo funcione de forma automática, criamos um script para Windows:
   ```powershell
   # Para PostgreSQL (Padrão)
   .\create-tedros-data.ps1 -Database postgres
   # Para H2
   .\create-tedros-data.ps1 -Database h2
   ```
   *Para o PostgreSQL, este script sobe um contêiner local com o banco. Para o H2, ele varre a sua pasta de usuário (home), cria o diretório necessário e faz a cópia do `init.sql` se ele não existir.*

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