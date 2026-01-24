Data: 24-01-2026
Responsável: Paranauê Labs
Status: Aprovado

## Contexto
Atualmente a empresa possui uma infraestrutura distribuída onde cada filial mantém seu próprio banco de dados local. A cada 5 minutos, um processo de sincronização coleta dados das filiais e atualiza a matriz. Quando ocorrem falhas em equipamentos das filiais, é necessário transporte físico para manutenção, causando downtime significativo. O sistema administrativo de cadastro e o sistema laboratorial de análises operam de forma integrada, mas com bancos separados que se comunicam.

## Decisão
Implementar uma infraestrutura centralizada na matriz, utilizando um banco de dados centralizado. As filiais acessarão os sistemas via WAN através de conexões VPN seguras. A rede administrativa da matriz será segmentada em VLANs dedicadas para isolamento e segurança.

## Justificativa
A centralização foi escolhida baseada nos seguintes fatores:

1. Redução de Complexidade Operacional: Elimina a necessidade de manutenção física em 40 locais diferentes, reduzindo custos de deslocamento e tempo de resolução de problemas.
2. Consistência de Dados: Remove a necessidade de processos manuais de sincronização, garantindo dados atualizados em tempo real em toda a organização.
3. Segurança Aprimorada: Controle centralizado de acessos, backup unificado e monitoramento centralizado.
4. Escalabilidade: Facilita a abertura de novas filiais sem necessidade de infraestrutura local complexa.
5. Custo Total de Propriedade: Apesar do investimento inicial maior, reduz custos recorrentes de manutenção distribuída.

## Alternativas Consideradas
Alternativa 1: Manutenção do Modelo Atual (Distribuído)
Vantagens: Independência por filial, menor impacto em falhas de WAN
Desvantagens: Alto custo de manutenção, inconsistência de dados, complexidade de suporte
Rejeitada: Devido aos custos operacionais crescentes e riscos de inconsistência de dados

Alternativa 2: Híbrido (Dados Críticos Centralizados)
Vantagens: Balanceamento entre performance local e controle central
Desvantagens: Complexidade aumentada, necessidade de sincronização bidirecional
Rejeitada: Mantém complexidade de sincronização que queremos eliminar

Alternativa 3: Cloud Puro
Vantagens: Escalabilidade elástica, OPEX em vez de CAPEX
Desvantagens: Dependência de internet, custo recorrente alto, latência potencial
Rejeitada: Custo recorrente muito alto para o volume de dados e necessidade de baixa latência

## Consequências
Positivas
Operacional: Suporte remoto possível para 100% dos casos
Financeiro: Redução de custos com deslocamentos em ~80%
Dados: Eliminação de janelas de inconsistência
Segurança: Políticas de backup e acesso unificadas

Negativas
Dependência de WAN: Filiais ficam inoperantes se a conexão cair
Investimento Inicial: CAPEX significativo em infraestrutura de matriz
Latência: Potencial impacto na performance para filiais mais distantes
Capacitação: Equipe precisa treinar em novas tecnologias

## Mitigações Planejadas
Resiliência WAN: Links redundantes (fibra + 4G/5G) por filial
Cache Local: Implementação de Redis nas filiais para operação offline parcial
Migração Gradual: Piloto com 5 filiais antes de migração completa
Treinamento: Programa de capacitação de 40 horas para equipe de suporte

## Referências
Cisco Campus Network Design Guide
PostgreSQL High Availability Documentation
NIST Cybersecurity Framework
TCO Analysis: Centralized vs Distributed Infrastructure (Gartner, 2023)