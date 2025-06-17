# Dns-Bind9

Um script Bash para configurar servidores DNS com BIND9 no Debian, com suporte a servidores autoritativo (incluindo zona reversa e slave), cache ou encaminhamento. Este projeto é destinado a demonstrar habilidades em automação e administração de sistemas Linux. Não deve ser usado em ambientes de produção.

## Como Usar

### Pré-requisitos

- Debian 11 ou superior (testado no Debian 12).
- Acesso root (sudo).
- Conexão à internet.
- Recomendado: Testar em uma máquina virtual.

### 1. Clone o Repositório

```bash
git clone https://github.com/kurupt-on/Dns-Bind9
```

### 2. Configurar o Servidor DNS

```bash
sudo ./setup.sh
```

- Escolha o tipo de servidor:
  - **0**: Autoritativo (insira domínio, IP, e opte por zona reversa e/ou slave).
  - **1**: Cache.
  - **2**: Encaminhamento (insira dois IPs de encaminhadores, ex.: `8.8.8.8`, `8.8.4.4`).

### 3. Testar

Para autoritativo:

```bash
dig ns1.<seu-domínio>
```

**Saída esperada** (exemplo para `ns1.domain.local`):

```
;; ANSWER SECTION:
ns1.domain.local. 28800 IN A 192.168.55.110
```

Se configurou zona reversa:

```bash
dig -x 192.168.55.110
```

**Saída esperada**:

```
;; ANSWER SECTION:
110.55.168.192.in-addr.arpa. 28800 IN PTR ns1.domain.local.
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
- `LICENSE`: Licença sob a qual o projeto está licenciado.
- `README.md`: Este arquivo de documentação.
- `db.<domínio>`: Arquivo de zona para o servidor autoritativo.
- `db.<domínio>.rev`: Arquivo de zona reversa (se configurado).

## Licença

Este projeto está licenciado sob a Licença MIT.
