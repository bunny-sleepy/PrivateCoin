Name: [Wenhao Wang]

## Question 1

In the following code-snippet from `Num2Bits`, it looks like `sum_of_bits`
might be a sum of products of signals, making the subsequent constraint not
rank-1. Explain why `sum_of_bits` is actually a _linear combination_ of
signals.

```
        sum_of_bits += (2 ** i) * bits[i];
```

## Answer 1

In this snippet `sum_of_bits` increments by the product of `2 ** i` and `bits[i]`. Since `2 ** i` are constants for each term in the sum, which are not dependent on `bits[i]` or any other signals or variable, we have that `(2 ** i) * bits[i]` is a linear term. And since this line we only add these linear terms together without performing any multiplications with other signals, `sum_of_bits` remains a linear combination of variables.

## Question 2

Explain, in your own words, the meaning of the `<==` operator.

## Answer 2

The meaning of this operator is assign and constrain.
Suppose the left-hand-side is some signal `x`, and on the right-hand-side is some expression `E`.
After the `<==` operator, the signal `x` is assigned the value of `E`.
Meanwhile, the constraint `E - x = 0` is generated in the system.

## Question 3

Suppose you're reading a `circom` program and you see the following:

```
    signal input a;
    signal input b;
    signal input c;
    (a & 1) * b === c;
```

Explain why this is invalid.

## Answer 3

The fundamental reason is that `(a & 1) * b === c` is not a quadratic operation that looks like `A * B + C === 0`, where `A`, `B` and `C` are linear combination of signals.
Instead, it can be assigned then constrained, like

```
    signal tmp;
    tmp <-- (a & 1) * b;
    c === tmp;
```