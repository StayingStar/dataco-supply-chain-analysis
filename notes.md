# DataCo Supply Chain Analysis — Notes

## Project summary
Analysis of 180,519 order lines (2015–2018) from the DataCo supply chain dataset,
using PostgreSQL (pgAdmin), Tableau, and a Python AI agent.

---

## Finding 1 — Losses
The company sold about $36.7M in total and is profitable overall at $3.97M.
But money-losing order lines cost $3.88M — about 10.6% of sales — which wipes out
nearly half of what the profitable lines earn.

- 33,784 order lines (18.7%) lost money; average loss ~$115 per line; worst single line −$4,275
- Losses are similar across markets once market size is accounted for
  (Europe has the largest dollar loss, $1.15M, mostly because it is the biggest market;
  Pacific Asia has the highest loss share, only ~0.2 percentage points above Europe)
- Losses vary a lot by category: the worst 10 lose about 11%–19% of their sales
  (worst: [category 1], [category 2], [category 3])
- Recommendation: review pricing and discounts in the worst categories; fixing them
  could nearly double profit

## Finding 2 — Late deliveries
57.3% of shipped order lines (98,977 of 172,765, canceled orders excluded) arrive late.
The cause is unrealistic delivery promises, not slow shipping.

| Shipping mode  | Promised days | Actual days (avg) | Late % |
|----------------|---------------|-------------------|--------|
| First Class    | 1             | 2.00              | 100.0  |
| Second Class   | 2             | 3.99              | 79.8   |
| Same Day       | 0             | 0.48              | 47.9   |
| Standard Class | 4             | 3.99              | 39.8   |

- First Class promises 1 day and always takes 2 → late 100% of the time
- Second Class promises 2 days but takes ~4 — the same as Standard Class. Customers paying
  extra get no real speed advantage. The business should either make Second Class
  genuinely faster or stop charging a premium for it.
- Standard Class is on time on average, but 41,023 lines took 5–6 days.
  Lesson: averages hide spread — always check the distribution.
- Recommendation: set promises that match real delivery times. Trade-off: less
  attractive delivery offers for customers who pay for speed.

## Finding 3 — Fraud
All 4,062 suspected-fraud order lines came from transfer payments — about 8.1% of the
49,883 transfer lines — while no suspected fraud was recorded for any other payment type.

- Suspected fraud is about 2.3% of all order lines
- About 92% of transfers are genuine, so blocking transfers would lose far more good
  orders than bad ones
- Recommendation: add extra verification only for transfer payments, and confirm the
  fraud checks cover the other payment types, so we know the 0% is real

## Finding 4 — Delivery promise model (what-if)
I modelled how late deliveries would change if promises matched reality.

| Scenario                                   | Late rate |
|--------------------------------------------|-----------|
| Today                                      | 57.3%     |
| Every promise +1 day                       | 23.7%     |
| Every promise +2 days                      | 7.8%      |
| Every promise +3 days                      | 3.9%      |
| Targeted: First Class +1, Second Class +2  | 34.1%     |

- First Class always takes exactly 2 days but promises 1, so +1 day takes it from 100% to 0% late
- +1 for everyone gives the lowest late rate, but makes every service look slower
- The targeted fix only changes the two broken modes, keeping Standard and Same Day promises
- Recommendation: start with the targeted fix (57.3% → 34.1%) — it fixes broken promises
  without making working services look worse
- Possible next step: Second Class performs the same as Standard Class, so the company could
  merge them or drop the premium price