const BN = require('bn.js')
const UNITS = {
  EMBER: new BN(1),
  MICROFIRE: new BN(1e2),
  MILLIFIRE: new BN(1e5),
  FIRE: new BN(1e8),
  HECTOFIRE: new BN(1e10),
  KILOFIRE: new BN(1e11),
  MEGAFIRE: new BN(1e14),
  GIGAFIRE: new BN(1e17),
  TERAFIRE: new BN(1e20)
}

module.exports = {
  UNITS,
  toEmber,
  fromEmber,
  convert
}

function toEmber(int, unit = 'fire') {
  return convert(unit, int, 'ember')
}

function fromEmber(int, unit = 'fire') {
  return convert('ember', int, unit)
}

function toBN(int) {
  switch(typeof int) {
    case 'string':
      return new BN(int)
    case 'number':
      return new BN(int)
    case 'object':
      // .toString must resolve to a string
      return new BN(int.toString())
  }
}

function convert(current, int, future) {
  const intBN = toBN(int)
  const start = UNITS[current.toUpperCase()]
  const end = UNITS[future.toUpperCase()]
  return intBN.mul(start).div(end)
}
