# 🛠️ Histórico de Comandos e Operações do Ambiente

Este documento centraliza os principais comandos utilizados para a configuração, troubleshooting e manutenção do nosso ambiente Docker local.

---

## 1. Gerenciamento do Ciclo de Vida (Docker Compose)
Comandos utilizados para iniciar, parar e reconstruir os serviços do projeto.

* **Iniciar todos os serviços em segundo plano (detached):**
  ```powershell
  docker-compose up -d
  ```
* **Iniciar apenas um serviço específico (ex: h2db):**
  ```powershell
  docker compose up -d h2db
  ```
* **Parar e remover todos os contêineres e redes do projeto:**
  ```powershell
  docker-compose down
  ```
* **Reconstruir as imagens e iniciar os serviços (útil após alterar o Dockerfile):**
  ```powershell
  docker compose up -d --build
  ```
* **Reconstruir a imagem de serviços específicos sem iniciar:**
  ```powershell
  docker-compose build tomee1 tomee2
  ```
* **Forçar a recriação de um contêiner específico (ex: aplicar novos volumes/certificados no MongoDB):**
  ```powershell
  docker-compose up -d --force-recreate mongodb
  ```

---

## 2. Monitoramento e Diagnóstico (Logs)
Comandos para investigar o comportamento das aplicações em tempo real.

* **Acompanhar logs do TomEE 1 (node 1) em tempo real:**
  ```powershell
  docker compose logs -f tomee1
  ```
* **Acompanhar logs do TomEE 2 (node 2) em tempo real:**
  ```powershell
  docker compose logs -f tomee2
  ```
* **Verificar os logs de erro de inicialização do MongoDB (sem seguir em tempo real):**
  ```powershell
  docker logs tedros-mongodb
  ```

---

## 3. Inspeção e Manipulação de Arquivos nos Contêineres
Operações realizadas diretamente dentro dos contêineres em execução.

### Banco de Dados H2
* **Copiar banco de dados local para dentro do volume do H2:**
  ```powershell
  docker cp "D:\GitHub\Tedros-Box\Tedros\init\docker\backup\.tedrosData\." tedros-h2db:/opt/h2-data/
  ```
* **Inspecionar os arquivos dentro do diretório de dados do H2:**
  ```powershell
  docker exec tedros-h2db ls -lh /opt/h2-data/
  ```
* **Ajustar permissões (chmod 777) da pasta do H2 usando o usuário root:**
  ```powershell
  docker exec -u root -it tedros-h2db chmod -R 777 /opt/h2-data
  ```
* **Reiniciar o serviço do H2 após aplicar permissões ou copiar dados:**
  ```powershell
  docker compose restart h2db
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
  mkcert tedros.test h2db.tedros.test localhost 127.0.0.1 ::1
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