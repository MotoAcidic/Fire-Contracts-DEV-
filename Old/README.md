# FIRE
a repo for all things fire solidity / truffle development

## *WARNING*
this package is untested

need tests for all code (`.sol` + `.js`)

# contracts
use `contracts/*` to test the contracts you plan to build on fire.

# utils

```js
const { UNITS, fromEmber, toEmber, convert } = require('@firecommunity/fire/utils')
```

### `UNITS`
an object with the units as keys and the factor (1e8) as values.
```
ember
microfire
millifire
fire
hectofire
kilofire
megafire
gigafire
terafire
```

### `convert`
convert any unit into any other unit returns a BN.js value
```js
convert('ember', 200000000, 'fire') // 2<BN>
```

### `fromEmber`
convert `ember` unit to any other unit, default destination `fire`
```js
fromEmber(200000000)             // 2<BN>
fromEmber(200000000, 'fire')      // 2<BN>
fromEmber(200000000, 'millifire') // 2000<BN>
```

### `toEmber`
convert from any other unit to `ember`, default source `fire`
```js
fromEmber(2)                // 200000000<BN>
fromEmber(2, 'fire')         // 200000000<BN>
fromEmber(2000, 'millifire') // 200000000<BN>
```
