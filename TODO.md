# Qi Optimization TODO

## Board.validate/1 — Eliminate double traversal

- [ ] Fuse `compute_shape/1` and `verify_and_count/2` into a single pass that infers the expected shape from the first element at each level while simultaneously verifying rectangularity and counting squares/pieces.
- [ ] Remove standalone `length/1` calls in `compute_shape/2` (each is O(n) and redundant with the subsequent verification pass).
- [ ] Validate dimension limits (max 3 dimensions, max 255 per dimension) inline during the fused traversal instead of as a separate step over the shape list.

## Hands.validate/1 — Minor streamlining

- [ ] Inline both `count_hand/1` calls into a single recursive function that traverses first then second without allocating the intermediate `{:ok, first_count}` tuple.

## Benchmarking

- [ ] Add a `benchee` benchmark script (e.g., `bench/position_bench.exs`) covering common board sizes (1D, 8×8, 9×9, 9×10, 5×5×5) to measure before/after impact of each change.
