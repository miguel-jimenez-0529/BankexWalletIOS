//
//  SendingConfirmationController.swift
//  BankexWallet
//
//  Created by Korovkina, Ekaterina  on 4/8/2561 BE.
//  Copyright © 2561 Alexander Vlasov. All rights reserved.
//

import UIKit
import web3swift
import BigInt

class SendingConfirmationController: UIViewController, Retriable {

    // MARK: Outlets
    
    @IBOutlet weak var amountLabel: UILabel!
    @IBOutlet weak var toAddressLabel: UILabel!
    @IBOutlet weak var fromAddressLabel: UILabel!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var feeLabel: UILabel!
    @IBOutlet weak var gasPriceLabel: UILabel!
    @IBOutlet weak var totalFeeLabel: UILabel!
    
    @IBOutlet weak var stackView: UIView!
    @IBOutlet weak var nextButtonTopConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var bottomSpaceNextButtonConstraint: NSLayoutConstraint!
    @IBOutlet weak var internalViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var stackViewHeightConstraint: NSLayoutConstraint!
    
    // MARK:
    var transaction: TransactionIntermediate?
    var amount: String?
    var destinationAddress:String?
    var inputtedPassword: String?
    
    weak var transactionCompletionDelegate: SendingResultInformation?
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == "showSending",
            let destination = segue.destination as? SendingInProcessViewController else {
                return
        }
        transactionCompletionDelegate = destination
    }
    
    let tokensService = CustomERC20TokensServiceImplementation()
    let keysService: SingleKeyService = SingleKeyServiceImplementation()

    @IBAction func nextButtonTapped(_ sender: Any) {
        let sendEthService: SendEthService = tokensService.selectedERC20Token().address.isEmpty ?
            SendEthServiceImplementation() :
            ERC20TokenContractMethodsServiceImplementation()
        
        let token = tokensService.selectedERC20Token()
        let transactionModel = ETHTransactionModel(from: keysService.selectedAddress() ?? "",
                                                   to: destinationAddress ?? "",
                                                   amount: (amount ?? "") + " " + token.symbol,
                                                   date: Date(),
                                                   token: token,
                                                   key: keysService.selectedKey()!)

        
        performSegue(withIdentifier: "showSending", sender: self)
        sendEthService.send(transactionModel: transactionModel,
                            transaction: transaction!,
                            with: inputtedPassword ?? "") { (result) in
                                switch result {
                                case .Success(_):
                                    self.transactionCompletionDelegate?.transactionDidSucceed(withAmount: self.amount ?? "", address: self.destinationAddress ?? "")
                                case .Error(_):
                                    //TODO:
                                    self.transactionCompletionDelegate?.transactionDidFail()

                                }
//                                }
        }//transaction?.send(password: inputtedPassword ?? "", options: nil)
    }
    
    @IBOutlet weak var feeFullView: UIView!
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let fixedFrame = view.convert(stackView.frame, from: stackView.superview)
        var viewHeight: CGFloat =  -fixedFrame.minY
        if #available(iOS 11.0, *) {
            viewHeight -= view.safeAreaInsets.bottom
            viewHeight -= view.safeAreaInsets.top

            bottomSpaceNextButtonConstraint.constant = 0
        }
        internalViewHeightConstraint.constant = viewHeight
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        toAddressLabel.text = destinationAddress
        fromAddressLabel.text = SingleKeyServiceImplementation().selectedAddress()
        amountLabel.text = (amount ?? "") + " " + tokensService.selectedERC20Token().symbol
        //Getting gas limit
        guard let estimatedGas = transaction?.estimateGas(options: nil).value else {
            feeLabel.text = "Not defined"
            return
        }
        let formattedAmount = Web3.Utils.formatToEthereumUnits(estimatedGas, toUnits: .wei, decimals: 1)
        let web3 = WalletWeb3Factory.web3()
        web3.addKeystoreManager(keysService.keystoreManager())
        //Getting gas price
        guard let gasPrice = web3.eth.getGasPrice().value else {
            gasPriceLabel.text = "Not defined"
            return
        }
        let formattedGasPrice = Web3.Utils.formatToEthereumUnits(gasPrice, toUnits: .Gwei, decimals: 1)
        
        //Getting total fee
        guard let gasPriceInEth = Web3.Utils.formatToEthereumUnits(gasPrice, toUnits: .eth, decimals: 9) else { return }
        guard let gasPriceInDouble = Double(gasPriceInEth) else { return }
        guard let amount = amount, let amountInDouble = Double(amount) else {return}
        let totalFee = String(amountInDouble + gasPriceInDouble)
        
        feeLabel.text = (formattedAmount ?? "") + " Wei."
        gasPriceLabel.text = (formattedGasPrice ?? "") + " GWei."
        totalFeeLabel.text = totalFee + " Eth"
        nextButton.setTitle("Send " + (amountLabel.text ?? ""), for: .normal)
    }
    
    // MARK: Retriable
    func retryExisitngTransaction() {
        nextButtonTapped(self)
    }

}
