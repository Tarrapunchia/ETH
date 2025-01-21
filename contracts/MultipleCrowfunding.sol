// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// Uncomment this line to use console.log
// import "hardhat/console.sol";

struct Campaign {
        // money collected so far
        uint256 collectedFunds; // la voglio 256 perche' i token seguono questo range
        
        // obiettivo minimo nel founding
        uint256 minGoalToCollect;

        // va beh...
        uint256 numOfContributors;

        // timestamp of the campaign end
        uint256 campaingEndTime;

        // address di chi crea la campagna
        address adminCampaign;

        // id campaign
        uint256 idCampaign;

        // mapping chiave-valore dei contribuiti
        mapping(address => uint256) contribution;

}

contract Crowfunding {
    /// EVENTS
        // indexed ci dice che questo tipo di eventi e' indicizzato in base ai contributor
        event Contribution(address indexed contributor, uint256 amount);
        event ClaimCampaign(address indexed withdrawer, uint256 amount);
        event Withdraw(address withdrawer, uint256 amount);
        event EmergencyWithdraw(address withdrawer, uint256 amount);


    /// ERRORS
        // se la campagna e' finita
        error CampaignEnded();
        error NotExistingContribution();
        error InvalidAmount();
        error AlreadyDonated();
        error NotAdmin();
        error GoalNotReached();
        error CampaignNotEnded();
        error GoalReached();


    /// STATE VARIABLES

        // id campaign
        uint256 idCampaign;

        // address del tonek USDC nella chain
        address public usdcTokenAddress;

        // mapping per campagne multiple
        mapping(uint256 => Campaign) Campaigns;

    /// CONTRUCTOR
        constructor(uint256 _minGoalToCollect, address _adminCampaign, uint256 _endTime) {
            // adminCampaign = _adminCampaign;
            // minGoalToCollect = _minGoalToCollect;
            // campaingEndTime = _endTime;
        }


    /// METHODS

        // init campaign
        function initCampaign(uint256 _minGoalToCollect, address _adminCampaign, uint256 _endTime) public {
            Campaigns[idCampaign].adminCampaign = _adminCampaign;
            Campaigns[idCampaign].campaingEndTime = _endTime;
            Campaigns[idCampaign].minGoalToCollect = _minGoalToCollect;
            idCampaign++;
        }

        // Donations
        function contribute(uint256 amount, uint256 _idCampaign) public payable {


            Campaign storage _buf = Campaigns[_idCampaign];
            // se la campagna e' finita esco dal metodo (con revert) ritornando un errore custom campaign_ended
            if (block.timestamp > _buf.campaingEndTime)
                revert CampaignEnded();
            // altermativa si puo fare con require

            if (amount == 0)
                revert InvalidAmount();
            if (_buf.contribution[msg.sender] > 0)
                revert AlreadyDonated();
            // prima del transerFrom il contratto deve chiedere l'approval da parte dell'utente per spendere i soldi
            // richiesti dal contratto (questo funziona solo in direzione del contratto visto che vado ad eseguire
            // un metodo definito dal contratto e quindi la sicurezza e' sbilanciata verso il contratto via)
            // approve(address spender, uint256 value) → bool
            // Sets a value amount of tokens as the allowance of spender over the caller’s tokens.
            // Returns a boolean value indicating whether the operation succeeded.
            // tale approve autorizza fino ad una soglia che puo' esser consumata anche in piu' transazioni col
            // contratto

            // si occupa gia IERC20.metodo di controllare se il tutto funziona ed a mandare gli eventi
            IERC20(usdcTokenAddress).transferFrom(msg.sender, _buf.adminCampaign, amount);
            _buf.collectedFunds += amount;
            _buf.numOfContributors++;
            _buf.contribution[msg.sender] = amount;

            emit Contribution(msg.sender, amount);
        }

        // Recupero palanche da parte del donatore
        function withdraw(uint256 _idCampaign) public payable {
            Campaign storage _buf = Campaigns[_idCampaign];

            // se la campagna e' finita esco dal metodo (con revert) ritornando un errore custom CampaignEnded
            if (block.timestamp > _buf.campaingEndTime)
                revert CampaignEnded();
            
            // prelevo il valore della quantita' di soldi donati dall'utente delle donazioni
            uint256 amountDonated = _buf.contribution[msg.sender];

            // controllo se la donazione totale e' nulla
            if (amountDonated == 0)
                revert NotExistingContribution();

            // la differenza tra transfer e transferFrom e che il primo lo uso se voglio DARE i soldi dal contratto (mi serve solo il to) mentre il secondo
            // se voglio DARE i soldi al contratto (mi serve il from ed il to)
            IERC20(usdcTokenAddress).transfer(msg.sender, amountDonated);
            _buf.contribution[msg.sender] = 0;
            _buf.collectedFunds -= amountDonated;
            _buf.numOfContributors--;

            emit Withdraw(msg.sender, amountDonated);

        }

        // Prelievo dei soldi da parte dell'admin quando sono stati raggiunti gli obiettivi economici && di tempo
        function claimFunds(uint256 _idCampaign) public payable onlyAdmin(_idCampaign){
            Campaign storage _buf = Campaigns[_idCampaign];

            // if (msg.sender != adminCampaign)
            //     revert NotAdmin();
            if (_buf.collectedFunds < _buf.minGoalToCollect)
                revert GoalNotReached();
            if (block.timestamp < _buf.campaingEndTime)
                revert CampaignNotEnded();

            IERC20(usdcTokenAddress).transfer(_buf.adminCampaign, _buf.collectedFunds);

            emit ClaimCampaign(msg.sender, _buf.collectedFunds);
        }

        // recuper soldi se la campagna e' terminata ma il goal non e' stato raggiunto
        function emergencyWithdraw(uint256 _idCampaign) public payable {
            Campaign storage _buf = Campaigns[_idCampaign];

            if (block.timestamp < _buf.campaingEndTime)
                revert CampaignNotEnded();
            if (_buf.collectedFunds >= _buf.minGoalToCollect)
                revert GoalReached();
            uint256 _amount = _buf.contribution[msg.sender];
            if (_amount == 0)
                revert NotExistingContribution();

            IERC20(usdcTokenAddress).transferFrom(_buf.adminCampaign, msg.sender, _amount);
            _buf.collectedFunds -= _amount;
            _buf.numOfContributors--;
            _buf.contribution[msg.sender] = 0;

            emit EmergencyWithdraw(msg.sender, _amount);
        }

    /// MODIFIERS
        // sono una kw di solidity al cui intero va una logica
        modifier onlyAdmin(uint256 _idCampaign) {
            if (msg.sender != Campaigns[_idCampaign].adminCampaign)
                revert NotAdmin();
            _;
        // il modificatore deve terminare con _;
        }
        // questi poi vanno messi nella dichiarazione di metodo in questa maniera
        // function nomeMetodo() public payable nomeModificatore {...}
        // questo fa si che il controllo dentro il mod avvenga in autmatco alla chiamata di fne
        // (VEDERE CLAIMFUNDS())





    //metadati
    //  raccolti
    //  obiettivo
    //  sostenitori
    //  titolo/img/descrizione

    
}
