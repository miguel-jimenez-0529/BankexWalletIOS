//
//  WalletsViewController.swift
//  BankexWallet
//
//  Created by Vladislav on 22.07.2018.
//  Copyright © 2018 Alexander Vlasov. All rights reserved.
//

import UIKit

protocol WalletsDelegate:class  {
    func didTapped(with wallet:HDKey)
}

class WalletsViewController: UIViewController {
    
    @IBOutlet weak var tableView:UITableView!
    
    let service: GlobalWalletsService = HDWalletServiceImplementation()
    var listWallets = [HDKey]()
    var selectedWallet:HDKey? {
        return service.selectedKey()
    }
    
    weak var delegate:WalletsDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Wallets"
        tableView.dataSource = self
        tableView.delegate = self
        listWallets = (service.fullHDKeysList() ?? [HDKey]()) + (service.fullListOfSingleEthereumAddresses() ?? [HDKey]())
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(goBack(_:)))
        NotificationCenter.default.addObserver(forName: DataChangeNotifications.didChangeWallet.notificationName(), object: nil, queue: nil) { _ in
            self.tableView.reloadData()
        }
    }
    
    @objc func goBack(_ sender:UIButton) {
        performSegue(withIdentifier: "backSegue", sender: nil)
    }

    

}

extension WalletsViewController:UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? 1 : listWallets.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: WalletCell.identifier, for: indexPath) as! WalletCell
        switch indexPath.section {
        case 0:
            cell.configure(wallet: selectedWallet!)
        case 1:
            let currentWallet = listWallets[indexPath.row]
            cell.configure(wallet: currentWallet)
        default: break
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return section == 1 ? "CHOOSE A WALLET..." : ""
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 62.0
    }
}

extension WalletsViewController:UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 1 {
            let wallet = listWallets[indexPath.row]
            service.updateSelected(address: wallet.address)
            tableView.reloadData()
            delegate?.didTapped(with: wallet)
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
