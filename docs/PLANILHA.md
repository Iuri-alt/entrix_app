# Planilha Controle Financeiro → Entrix

O Entrix implementa a planilha `Controle_Financeiro_2026-2027.xlsx`. Os dados ficam na
API (`entrix_api`); todos os cálculos rodam em Dart puro em `lib/domain/calc/` e são
testados contra os valores calculados pelo Excel (`test/domain/finance_plan_spreadsheet_test.dart`).

## Abas → módulos

| Aba | Dados (API) | Cálculo | Tela |
|---|---|---|---|
| Config | `PlanSettings` (`/settings/`) | `PlanSettings.planMonths`, `today()` | Ajustes › Plano e Categorias |
| Produtos | `Product` (`/products/`) | `ProductPlan` (falta, status, alerta) | Produtos |
| Lançamentos | `FinanceTransaction` (`/transactions/`) | `CashFlow` | Lançamentos |
| Fluxo de caixa | — | `CashFlow.table`, `CashFlow.byCategory` | Planejamento › Fluxo de caixa; Painel |
| Renda | campos `budget_*` e `plan_base` | `IncomePlan` | Planejamento › Renda |
| Por Produto | — | `ProductPlan` (meses, por mês/semana/dia) | Planejamento › Por produto |
| Cronograma | — | `SavingsSchedule` | Planejamento › Cronograma; Painel |
| Prioridades | — | `PriorityPlan` (`MinimoMensal`) | Planejamento › Prioridades |
| Simulação | campo `scenarios` | `Scenario` | Planejamento › Simulação |
| Resumo | — | `FinancePlan` + `summary_alerts.dart` | Painel (com filtro de mês/ano) |
| Como usar | — | — | Ajustes › Como usar |

## Nomes definidos

| Nome | Onde |
|---|---|
| `Hoje` | `PlanSettings.today()` (data do dia ou a data simulada em Ajustes) |
| `InicioPlano`, `PrazoFinal`, `MesesPlano` | `planStart`, `planEnd`, `planMonths` |
| `DiasProximo`, `LimiteApertada` | `daysSoon`, `tightLimit` |
| `TotalProdutos`, `TotalGuardado`, `TotalFalta` | `FinancePlan.totalProducts`, `totalSaved`, `totalMissing` |
| `MetaMensal` | `FinancePlan.monthlyGoal` |
| `MinimoMensal` | `PriorityPlan.minimumMonthly` |
| `Disponivel` | `IncomePlan.available` |
| `MesAtual` | `FinancePlan.currentPlanMonth` |

## Diferenças intencionais em relação à planilha

1. **Sem teto de 24 meses / 30 produtos / 500 lançamentos.** O plano pode ter qualquer
   duração, e a Simulação mostra o mês real em vez de "Mais de 24 meses".
2. **Lançamentos de qualquer data.** O Fluxo de caixa tem a visão "Histórico", que vai
   além dos meses do plano. A média "Realizado" (Renda) continua usando só os meses do plano.
3. **Despesas por categoria somam todas as despesas.** A planilha ignora despesas lançadas
   com categoria fora da lista J7:J21 (ex.: "Aluguel garagem" com "Outras receitas"),
   e por isso o total por categoria (2.445,33) não bate com o total de despesas (2.645,33).
   O app mostra essas categorias e o total bate.
4. **Disponível previsto calculado.** Renda!B9 era um valor digitado (0); no app é
   renda − gastos fixos − variáveis − outros compromissos.
5. **Receita não tem grupo.** O grupo de despesa é descartado em receitas (a planilha já o
   ignorava nos cálculos).
6. **Painel com filtro de mês/ano.** Os indicadores do mês e os alertas de saldo usam o
   período escolhido. Com "Ano todo", a meta do ano é o mínimo mensal × 12.
