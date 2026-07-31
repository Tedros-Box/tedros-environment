# Histórico de Comandos e Operações do Ambiente

Este documento centraliza os principais comandos utilizados para a configuração, troubleshooting e manutenção do nosso ambiente Docker local.

O banco default é **PostgreSQL**, selecionado por feature flag (`TEDROS_DB_*` + Compose `--profile postgres`). Sempre informe o profile ao subir o stack.

---

## 1. Gerenciamento do Ciclo de Vida (Docker Compose)
Comandos utilizados para iniciar, parar e reconstruir os serviços do projeto.

* **Iniciar o stack com PostgreSQL (detached):**
  ```powershell
  docker compose --profile postgres --env-file .env.postgres up -d
  ```
* **Reconstruir as imagens e iniciar (útil após alterar o Dockerfile):**
  ```powershell
  docker compose --profile postgres --env-file .env.postgres up -d --build
  ```
* **Parar e remover contêineres e redes do projeto:**
  ```powershell
  docker compose --profile postgres --env-file .env.postgres down
  ```
* **Reconstruir a imagem de serviços específicos sem iniciar:**
  ```powershell
  docker compose build tomee1 tomee2
  ```
* **Forçar a recriação de um contêiner específico (ex.: MongoDB):**
  ```powershell
  docker compose --profile postgres --env-file .env.postgres up -d --force-recreate mongodb
  ```

---

## 2. Monitoramento e Diagnóstico (Logs)
Comandos para investigar o comportamento das aplicações em tempo real.

* **Acompanhar logs do TomEE 1 (node 1) em tempo real:**
  ```powershell
  docker compose --profile postgres --env-file .env.postgres logs -f tomee1
  ```
* **Acompanhar logs do TomEE 2 (node 2) em tempo real:**
  ```powershell
  docker compose --profile postgres --env-file .env.postgres logs -f tomee2
  ```
* **Logs do PostgreSQL:**
  ```powershell
  docker compose --profile postgres --env-file .env.postgres logs -f postgres
  ```
* **Verificar os logs de erro de inicialização do MongoDB (sem seguir em tempo real):**
  ```powershell
  docker logs tedros-mongodb
  ```

---

## 3. Inspeção e Manipulação de Arquivos nos Contêineres
Operações realizadas diretamente dentro dos contêineres em execução.

### Banco de Dados PostgreSQL
* **Checar saúde / prontidão:**
  ```powershell
  docker exec -it tedros-postgres pg_isready -U tdrs -d tedros
  ```
* **Listar schemas:**
  ```powershell
  docker exec -it tedros-postgres psql -U tdrs -d tedros -c "\dn"
  ```
* **Listar tabelas de um schema (ex.: tedros_core):**
  ```powershell
  docker exec -it tedros-postgres psql -U tdrs -d tedros -c "\dt tedros_core.*"
  ```
* **Abrir sessão interativa `psql`:**
  ```powershell
  docker exec -it tedros-postgres psql -U tdrs -d tedros
  ```
* **Dump de backup:**
  ```powershell
  docker exec tedros-postgres pg_dump -U tdrs tedros > tedros-backup.sql
  ```

### Servidores TomEE
* **Inspecionar a pasta de instalação do TomEE:**
  ```powershell
  docker exec tedros-tomee1 ls -lh /usr/local/tomee/
  ```
* **Verificar as bibliotecas comuns (libs) instaladas:**
  ```powershell
  docker exec tedros-tomee1 ls -lh /usr/local/tomee/lib
  ```
* **Extrair a pasta de logs do TomEE 1 para a máquina local (para análise offline):**
  ```powershell
  docker cp tedros-tomee1:/usr/local/tomee/logs/ ./logs_tomee1/
  ```
* **Conferir datasource (env `TEDROS_DB_*`):**
  ```powershell
  docker exec tedros-tomee1 printenv | findstr TEDROS_DB
  ```

### MongoDB
* **Injetar o script de inicialização diretamente via mongosh:**
  ```powershell
  Get-Content mongo-init.js | docker exec -i tedros-mongodb mongosh itsupport
  ```

---

## 4. Instalação de Ferramentas no Windows (Scoop e mkcert)
Passo a passo utilizado para instalar o gerenciador de pacotes Scoop e a ferramenta de certificados mkcert.

* **Permitir a execução de scripts locais no PowerShell:**
  ```powershell
  Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
  ```
* **Instalar o gerenciador de pacotes Scoop:**
  ```powershell
  iwr -useb get.scoop.sh | iex
  ```
* **Adicionar o repositório principal (bucket) do Scoop:**
  ```powershell
  scoop bucket add main
  ```
* **Atualizar os repositórios do Scoop:**
  ```powershell
  scoop update
  ```
* **Instalar a ferramenta mkcert:**
  ```powershell
  scoop install mkcert
  ```

---

## 5. Configuração de Segurança e Certificados (TLS/SSL)
Comandos para gerar certificados locais e configurar a cadeia de confiança no ambiente de desenvolvimento.

* **Navegar até a pasta de armazenamento dos certificados locais:**
  ```powershell
  cd D:\GitHub\Tedros-Box\Tedros\init\docker\nginx\ssl_local
  ```
* **Gerar certificados para os domínios locais e localhost usando o mkcert:**
  ```powershell
  mkcert tedros.test localhost 127.0.0.1 ::1
  ```
* **Importar a Autoridade Certificadora (CA) raiz do mkcert para o cacerts do Java (JDK 17):**
  ```powershell
  # 1. Definir variáveis de caminho
  $caFile = "C:\Users\User\AppData\Local\mkcert\rootCA.pem"
  $keytool = "D:\java\jdk\jdk-17.0.10\bin\keytool.exe"
  $cacerts = "D:\java\jdk\jdk-17.0.10\lib\security\cacerts"

  # 2. Executar a importação via keytool
  & $keytool -import -trustcacerts -keystore $cacerts -storepass changeit -alias mkcert-local -file $caFile -noprompt
  ```
