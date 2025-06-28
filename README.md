# Dns-Bind9

Um script Bash para configurar servidores DNS com Bind9 no Debian, com suporte a servidores autoritativo (com zona reversa, slave e views), cache (com encaminhamento opcional) e encaminhamento. Inclue configurações de ACLs para controle de acesso. **Este projeto não é destinado para ambientes de produção.**

## Como Usar

### Pré-requisitos

- Debian 11 ou superior (testado no Debian 12).
- Acesso root (sudo).
- Conexão à internet.
- Recomendado: Testar em uma máquina virtual.

### 1. Clone o Repositório

```bash
git clone https://github.com/kurupt-on/Dns-Bind9
cd Dns-Bind9
```

### 2. Configurar o Servidor DNS

```bash
sudo ./setup.sh
```

- Escolha o tipo de servidor:
  - **0**: Autoritativo (insira domínio, IP, e opte por zona reversa, slave, views e ACLs).
  - **1**: Cache (opte por encaminhamento, dominio interno, DNSSEC e ACLs).
  - **2**: Encaminhamento (insira dois IPs de encaminhadores, ex.: `8.8.8.8`, `8.8.4.4`, e opter por ACLs).

- Opcional: 
  - **E**: Configurações extras (adcionar ACLs ou habilitar/desabilitar views).
  - **S**: Sair.

### 3. Testar

Para autoritativo:

```bash
dig ns1.<seu-domínio>
```

**Saída esperada** (exemplo para `ns1.domain.lan`):

```
;; ANSWER SECTION:
ns1.domain.lan. 28800 IN A 192.168.55.110
```

Se configurou zona reversa:

```bash
dig -x 192.168.55.110
```

**Saída esperada**:

```
;; ANSWER SECTION:
110.55.168.192.in-addr.arpa. 28800 IN PTR ns1.domain.lan.
```

Para cache ou encaminhamento:

```bash
dig @localhost google.com
```

**Saída esperada**: Retorna o endereço IP de `google.com`.

## Solução de Problemas

- Verifique o status do serviço:

  ```bash
  systemctl status named.service
  ```

- Consulte os logs:

  ```bash
  journalctl -r -u named.service
  ```


- Valide a configuração:

  ```bash
  named-checkconf
  named-checkzone <seu-domínio> /etc/bind/db.<seu-domínio>
  ```

## Arquivos

- `setup.sh`: Script principal que chama as funções.
- `functions.sh`: Contém as funções de configuração.
- `LICENSE`: Licensa do projeto (MIT).
- `README.md`: Este arquivo de documentação.
- `config.swp`: Arquivo temporáio para ACLs.
- `db.<domínio>`: Arquivo de zona para o servidor autoritativo.
- `db.<domínio>.rev`: Arquivo de zona reversa (se configurado).

## Licença

Este projeto está licenciado sob a Licença MIT.
