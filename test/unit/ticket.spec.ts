import {expect} from 'chai';
import {ethers} from 'hardhat';

describe.skip('Contract Bubbles', function () {
    let ticketEvents;
    let signers;

    before(async () => {
        signers = await ethers.getSigners();
        const TicketEvents = await ethers.getContractFactory('TicketEvents', signers[0]);
        ticketEvents = await TicketEvents.deploy("Christmas Party", [
            100,
            Math.floor(Date.now() / 1000) + ( 24 * 60 * 60  * 10 ), //in 10 days
            ( 24 * 60 * 60  * 2 ), //2 days
            "IBIZA",
            "NEW YORK",
            "CHRIST MAS PARTY",
            "SOMETHING COOL",
            0,
            2,
            18,
            "WE ROCKS"
        ]);
    });

    it('should show max supply', async () => {
        const supply = await ticketEvents.maxSupply();
        expect(supply.toNumber()).to.be.eq(100);
    });

    it('should buy ticket', async () => {
        await ticketEvents.buyTicket();
        const [userTicket] = await ticketEvents.walletOfOwner(signers[0].address);
        const attributes = await ticketEvents.tokenURI(userTicket.toNumber());
        console.log(attributes)
    });
});
