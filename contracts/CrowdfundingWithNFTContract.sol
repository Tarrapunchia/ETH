// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./CustomNFT.sol";
// Uncomment this line to use console.log
// import "hardhat/console.sol";

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
        error InvalidAddress();


    /// STATE VARIABLES

        // money collected so far
        uint256 public collectedFunds; // la voglio 256 perche' i token seguono questo range
        
        // obiettivo minimo nel founding
        uint256 public minGoalToCollect;

        // va beh...
        uint256 public numOfContributors;

        // timestamp of the campaign end
        uint256 public campaingEndTime;

        // address di chi crea la campagna
        address public adminCampaign;

        // address del tonek USDC nella chain
        address public usdcTokenAddress;

        // address del contratto del token
        CustomNFT public tokenContract;

        // mapping chiave-valore dei contribuiti
        mapping(address => uint256) public contribution;

        // mapping per campagne multiple
        mapping(uint256 => mapping(address => uint256)) contribtionByCampaign;



    /// CONTRUCTOR
        constructor(uint256 _minGoalToCollect, address _adminCampaign, uint256 _endTime, address _tokenContractAddress) {
            adminCampaign = _adminCampaign;
            minGoalToCollect = _minGoalToCollect;
            campaingEndTime = _endTime;
            tokenContract = CustomNFT(_tokenContractAddress);
        }


    /// METHODS


        function setCustomNFTAddress(address _customNFTAddress) public onlyAdmin {
            if (address(tokenContract) != address(0))
                revert InvalidAddress();
            tokenContract = CustomNFT(_customNFTAddress);
        }

        // Donations
        function contribute(uint256 amount) public payable {
            // se la campagna e' finita esco dal metodo (con revert) ritornando un errore custom campaign_ended
            if (block.timestamp > campaingEndTime)
                revert CampaignEnded();
            // altermativa si puo fare con require

            if (amount == 0)
                revert InvalidAmount();
            if (contribution[msg.sender] > 0)
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
            IERC20(usdcTokenAddress).transferFrom(msg.sender, adminCampaign, amount);
            collectedFunds += amount;
            numOfContributors++;
            contribution[msg.sender] = amount;

            // chiamo il metodo direttamente, IMPORTANTE CHE INITIAL OWNER SIA SETTATO BENE
            tokenContract.safeMint(msg.sender);
            emit Contribution(msg.sender, amount);
        }

        // Recupero palanche da parte del donatore
        function withdraw() public payable {
            // se la campagna e' finita esco dal metodo (con revert) ritornando un errore custom CampaignEnded
            if (block.timestamp > campaingEndTime)
                revert CampaignEnded();
            
            // prelevo il valore della quantita' di soldi donati dall'utente delle donazioni
            uint256 amountDonated = contribution[msg.sender];

            // controllo se la donazione totale e' nulla
            if (amountDonated == 0)
                revert NotExistingContribution();

            // la differenza tra transfer e transferFrom e che il primo lo uso se voglio DARE i soldi dal contratto (mi serve solo il to) mentre il secondo
            // se voglio DARE i soldi al contratto (mi serve il from ed il to)
            IERC20(usdcTokenAddress).transfer(msg.sender, amountDonated);
            contribution[msg.sender] = 0;
            collectedFunds -= amountDonated;
            numOfContributors--;

            emit Withdraw(msg.sender, amountDonated);

        }

        // Prelievo dei soldi da parte dell'admin quando sono stati raggiunti gli obiettivi economici && di tempo
        function claimFunds() public payable onlyAdmin{
            // if (msg.sender != adminCampaign)
            //     revert NotAdmin();
            if (collectedFunds < minGoalToCollect)
                revert GoalNotReached();
            if (block.timestamp < campaingEndTime)
                revert CampaignNotEnded();

            IERC20(usdcTokenAddress).transfer(adminCampaign, collectedFunds);

            emit ClaimCampaign(msg.sender, collectedFunds);
        }

        // recuper soldi se la campagna e' terminata ma il goal non e' stato raggiunto
        function emergencyWithdraw() public payable {
            if (block.timestamp < campaingEndTime)
                revert CampaignNotEnded();
            if (collectedFunds >= minGoalToCollect)
                revert GoalReached();
            uint256 _amount = contribution[msg.sender];
            if (_amount == 0)
                revert NotExistingContribution();

            IERC20(usdcTokenAddress).transferFrom(adminCampaign, msg.sender, _amount);
            collectedFunds -= _amount;
            numOfContributors--;
            contribution[msg.sender] = 0;

            emit EmergencyWithdraw(msg.sender, _amount);
        }

    /// MODIFIERS
        // sono una kw di solidity al cui intero va una logica
        modifier onlyAdmin() {
            if (msg.sender != adminCampaign)
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
