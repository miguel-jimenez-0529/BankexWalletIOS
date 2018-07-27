//
//  ConfirmViewController.swift
//  BankexWallet
//
//  Created by Vladislav on 24.06.2018.
//  Copyright © 2018 Alexander Vlasov. All rights reserved.
//

import UIKit
import web3swift
import BigInt

class ConfirmViewController: UITableViewController {
    
    //IBOutlets
    
    @IBOutlet weak var fromLabel:UILabel!
    @IBOutlet weak var toLabel:UILabel!
    @IBOutlet weak var gasPriceLabel:UILabel!
    @IBOutlet weak var amountLabel:UILabel!
    @IBOutlet weak var feeLabel:UILabel!
    @IBOutlet weak var gasLimitLabel:UILabel!
    @IBOutlet weak var walletNameLabel: UILabel!
    
    //Properties
    
    
    var fromAddr:String {
        guard let addr = getFromAddress() else { return " " }
        return addr
    }
    var gasPrice:String!
    var gasLimit:String!
    var transaction:TransactionIntermediate!
    lazy var fee: String? = self.formattedFee()
    var amount:String!
    var name: String!
    
    let tokenService = CustomERC20TokensServiceImplementation()
    let keyService = SingleKeyServiceImplementation()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureTableView()
    }
    
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 7
    }
    
    func configureTableView() {
        tableView.allowsSelection = false
        tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 1))
        tableView.separatorInset.right = 15.0
    }
    
    func configure(_ dict:[String:Any]) {
        gasLimit = dict["gasLimit"] as? String
        gasPrice = dict["gasPrice"] as? String
        transaction = dict["transaction"] as? TransactionIntermediate
        amount = dict["amount"] as? String
        name = dict["name"] as? String
    }
    
    func updateUI() {
        gasLimitLabel.text = gasLimit
        gasPriceLabel.text = gasPrice
        toLabel.text = transaction.transaction.to.address
        amountLabel.text = amount
        fromLabel.text = fromAddr
        feeLabel.text = fee
        walletNameLabel.text = name
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateUI()
    }
    
    //Helper
    
    func getFromAddress() -> String? {
        let service = SingleKeyServiceImplementation()
        let addr = service.selectedWallet()?.address
        return addr
    }
    
    func formattedFee() -> String? {
        let gasPrice = BigUInt(Double(self.gasPrice)! * pow(10, 9))
        guard let gasLimit = BigUInt(self.gasLimit) else { return "" }
        return Web3.Utils.formatToEthereumUnits((gasPrice * gasLimit), toUnits: .eth, decimals: 10)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let successVC = segue.destination as? SendingSuccessViewController, let sentTrans = sender as? TransactionSendingResult {
            
            successVC.transactionAmount = Web3.Utils.formatToEthereumUnits(sentTrans.transaction.value, toUnits: .eth)
            successVC.addressToSend = sentTrans.transaction.to.address
        } else if let errorVC = segue.destination as? SendingErrorViewController {
            guard let error = sender as? String else { return }
            errorVC.error = error
        }
    }
    
    
    @IBAction func sendTapped() {
        let sendEthService: SendEthService = tokenService.selectedERC20Token().address.isEmpty ? SendEthServiceImplementation() : ERC20TokenContractMethodsServiceImplementation()
        let token  = tokenService.selectedERC20Token()
        let model = ETHTransactionModel(from: fromAddr, to: toLabel.text ?? "", amount: amount, date: Date(), token: token, key:keyService.selectedKey()!)
        self.performSegue(withIdentifier: "waitSegue", sender: nil)
        sendEthService.send(transactionModel: model, transaction: transaction) { (result) in
            switch result {
            case .Success(let res):
                self.performSegue(withIdentifier: "successSegue", sender: res)
            case .Error(let error):
                var valueToSend = ""
                if let error = error as? Web3Error {
                    switch error {
                    case .nodeError(let text):
                        valueToSend = text
                    default:
                        break
                    }
                }
                self.performSegue(withIdentifier: "showError", sender: valueToSend)
            }
        }
    }
    
}