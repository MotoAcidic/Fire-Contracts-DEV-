const FIRE = artifacts.rquire('FIRE');

contract('FIRE', accounts => {

    const _name = 'Fire Network';
    const _symbol = 'FIRE';
    const _decimals = 18;

    beforeEach({
        FIRE.new(_name, _symbol, _decimals);
    });
    describe('token attributes', function() {
        it('has the correct name', function() {

        });

        it('has the correct symbol', function () {

        });

        it('has the correct decimals', function() {

        });
    })
})