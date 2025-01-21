// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract Crowfunding {
    /// EVENTS
        // indexed ci dice che questo tipo di eventi e' indicizzato in base ai contributor
        event Contribution(address indexed contributor, uint256 amount);

    /// ERRORS
        // se la campagna e' finita
        error campaign_ended();

    /// STATE VARIABLES

        // money collected so far
        uint256 public collected_funds; // la voglio 256 perche' i token seguono questo range
        
        // obiettivo minimo nel founding
        uint256 public min_goal_to_collect;

        // va beh...
        uint256 public num_of_contributors;

        // timestamp of the campaign end
        uint256 public campaing_end_time;

        // address di chi crea la campagna
        address public admin_campaign;

        // address del tonek USDC nella chain
        address public usdc_token_address;

        // mapping chiave-valore dei contribuiti
        mapping(address => uint256) public contribution;



    /// CONTRUCTOR
        constructor(uint256 _min_goal_to_collect, address _admin_campaign, uint256 _end_time) {
            admin_campaign = _admin_campaign;
            min_goal_to_collect = _min_goal_to_collect;
            campaing_end_time = _end_time;
        }


    /// METHODS

        // Donations
        function contribute(uint256 amount) public payable {
            // se la campagna e' finita esco dal metodo (con revert) ritornando un errore custom campaign_ended
            if (block.timestamp > campaing_end_time)
                revert campaign_ended();
            // altermativa si puo fare con require


            // si occupa gia IERC20.metodo di controllare se il tutto funziona ed a mandare gli eventi
            IERC20(usdc_token_address).transferFrom(msg.sender, admin_campaign, amount);
            collected_funds += amount;
            num_of_contributors++;
            contribution[msg.sender] = amount;

            emit Contribution(msg.sender, amount);
        }

        // Recupero palanche da parte del donatore
        function withdraw(uint256 amount) public payable {
            
        }

        // Prelievo dei soldi da parte dell'admin
        function claim_funds(uint256 amount) public payable {

        }

        // recuper soldi se la campagna e' terminata ma il goal non e' stato raggiunto
        function emergency_withdraw(uint256 amount) public payable {

        }

    /// MODIFIERS





    //metadati
    //  raccolti
    //  obiettivo
    //  sostenitori
    //  titolo/img/descrizione

    
}
