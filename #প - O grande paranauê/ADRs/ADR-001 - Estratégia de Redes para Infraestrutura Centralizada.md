**Data: 24-01-2026<br>
Responsável: Paranauê Labs<br>
Status: Aprovado**<br>

## **Contexto**<br>
Atualmente a empresa possui uma infraestrutura distribuída onde cada filial mantém seu próprio banco de dados local. A cada 5 minutos, um processo de sincronização coleta dados das filiais e atualiza a matriz. Quando ocorrem falhas em equipamentos das filiais, é necessário transporte físico para manutenção, causando downtime significativo. O sistema administrativo de cadastro e o sistema laboratorial de análises operam de forma integrada, mas com bancos separados que se comunicam.

## **Decisão**<br>
Implementar uma infraestrutura centralizada na matriz, utilizando um banco de dados centralizado. As filiais acessarão os sistemas via WAN através de conexões VPN seguras. A rede administrativa da matriz será segmentada em VLANs dedicadas para isolamento e segurança.

## **Justificativa**<br>
A centralização foi escolhida baseada nos seguintes fatores:<br>

**1.** Redução de Complexidade Operacional: Elimina a necessidade de manutenção física em 40 locais diferentes, reduzindo custos de deslocamento e tempo de resolução de problemas.<br>
**2.** Consistência de Dados: Remove a necessidade de processos manuais de sincronização, garantindo dados atualizados em tempo real em toda a organização.<br>
**3.** Segurança Aprimorada: Controle centralizado de acessos, backup unificado e monitoramento centralizado.<br>
**4.** Escalabilidade: Facilita a abertura de novas filiais sem necessidade de infraestrutura local complexa.<br>
**5.** Custo Total de Propriedade: Apesar do investimento inicial maior, reduz custos recorrentes de manutenção distribuída.<br>

## **Alternativas Consideradas<br>
**Alternativa 1: Manutenção do Modelo Atual (Distribuído)**<br>
**Vantagens:** Independência por filial, menor impacto em falhas de WAN<br>
**Desvantagens:** Alto custo de manutenção, inconsistência de dados, complexidade de suporte<br>
**Rejeitada:** Devido aos custos operacionais crescentes e riscos de inconsistência de dados<br>

**Alternativa 2: Híbrido (Dados Críticos Centralizados)**<br>
**Vantagens:** Balanceamento entre performance local e controle central<br>
**Desvantagens:** Complexidade aumentada, necessidade de sincronização bidirecional<br>
**Rejeitada:** Mantém complexidade de sincronização que queremos eliminar<br>

**Alternativa 3: Cloud Puro**<br>
**Vantagens:** Escalabilidade elástica, OPEX em vez de CAPEX<br>
**Desvantagens:** Dependência de internet, custo recorrente alto, latência potencial<br>
**Rejeitada:** Custo recorrente muito alto para o volume de dados e necessidade de baixa latência<br>

## **Consequências<br>
**Positivas**<br>
**Operacional:** Suporte remoto possível para 90% dos casos<br>
**Financeiro:** Redução de custos com deslocamentos em ~80%<br>
**Dados:** Eliminação de janelas de inconsistência<br>
**Segurança:** Políticas de backup e acesso unificadas<br>

**Negativas**<br>
**Dependência de WAN:** Filiais ficam inoperantes se a conexão cair<br>
**Investimento Inicial:** CAPEX significativo em infraestrutura de matriz<br>
**Latência:** Potencial impacto na performance para filiais mais distantes<br>
**Capacitação:** Equipe precisa treinar em novas tecnologias<br>

## **Mitigações Planejadas**<br>
**Resiliência WAN:** Links redundantes (fibra + 4G/5G) por filial<br>
**Cache Local:** Implementação de Redis nas filiais para operação offline parcial<br>
**Migração Gradual:** Piloto com 5 filiais antes de migração completa<br>
**Treinamento:** Programa de capacitação de 40 horas para equipe de suporte<br>

## **Referências**<br>
[Cisco Campus Network Design Guide](https://www.cisco.com/c/en/us/td/docs/solutions/CVD/Campus/cisco-campus-lan-wlan-design-guide.html)<br>
[PostgreSQL High Availability Documentation](https://www.postgresql.org/docs/current/high-availability.html)<br>
[NIST Cybersecurity Framework](https://nvlpubs.nist.gov/nistpubs/CSWP/NIST.CSWP.29.pdf)<br>
[TCO Analysis: Centralized vs Distributed Infrastructure (Gartner, 2023)](https://hypersense-software.com/blog/2025/07/31/cloud-vs-on-premise-infrastructure-guide/)