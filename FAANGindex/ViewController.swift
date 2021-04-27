//
//  ViewController.swift
//  KomissarovNP
//
//  Created by Николай on 30.01.2021.
//

import UIKit


class ViewController: UIViewController, UIAlertViewDelegate {
    
    // MARK: - UI
    
    @IBOutlet private weak var companyNameLabel: UILabel!
    @IBOutlet private weak var companyPickerView: UIPickerView!
    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet private weak var companySymbolLabel: UILabel!
    @IBOutlet private weak var priceLabel: UILabel!
    @IBOutlet private weak var priceChangeLabel: UILabel!
    @IBOutlet private weak var logo: UIImageView!
    @IBOutlet private weak var changeProc: UILabel!
    @IBOutlet private weak var mainTitle: UILabel!
    
    // MARK: - Private properties
    
    private lazy var companies = [
        "Facebook": "FB",
        "Apple": "AAPL",
        "Amazon": "AMZN",
        "Netflix": "NFLX",
        "Google": "GOOG",
        "Vanguard index FAANG": "VUG"
    ]
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        requestQuoteUpdate()
    }
    
    // MARK: - Private methods
    
    private func checkInternetConnection() -> Bool {
        guard Reachability.isConnectedToNetwork() == false else {
            return true
        }
        
        let alert = UIAlertController(title: "Error",
                                      message: "Network connection failed",
                                      preferredStyle: .alert)
        alert.addAction(.init(title: "OK", style: .cancel, handler: nil))
        alert.addAction(.init(title: "Update", style: .default, handler: { [weak self] _ in
            self?.requestQuoteUpdate()
        }))
        present(alert, animated: true, completion: nil)
        return false
    }
    
    private func setup() {
        companyNameLabel.text = "Stock"

        companyPickerView.dataSource = self
        companyPickerView.delegate = self
        
        activityIndicator.hidesWhenStopped = true
        
        mainTitle.font = .boldSystemFont(ofSize: 23)
        
    }
    
    private func requestQuote(for symbol: String) {
        guard checkInternetConnection() else { return }
        
        let token = "pk_fec0f85ad8c44fe5863eb209e4f14106"
        guard let url = URL(string:"https://cloud.iexapis.com/stable/stock/\(symbol)/quote?token=\(token)") else {
            return
        }
        
        let dataTask = URLSession.shared.dataTask(with: url) { [weak self] (data, response, error) in
            if let data = data,
               (response as? HTTPURLResponse)?.statusCode == 200,
               error == nil {
                self?.parseQuote(from: data)
            } else {
                print("Network Error!")
            }
        }
        dataTask.resume()
    }
    
    private func requestQuoteUpdate() {
        activityIndicator.startAnimating()
        companyNameLabel.text = "-"
        companySymbolLabel.text = "-"
        priceLabel.text = "-"
        priceChangeLabel.text = "-"
        
        
        let selectedRow = companyPickerView.selectedRow(inComponent: 0)
        let selectedSymbol = Array(companies.values)[selectedRow]
        
        requestQuote(for: selectedSymbol)
        loadCompanyLogo(for: selectedSymbol)
    }
    
    private func parseQuote(from data: Data) {
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data)
            
            guard
                let json = jsonObject as? [String: Any?],
                let companyName = json["companyName"] as? String,
                let companySymbol = json["symbol"] as? String,
                let price = json["latestPrice"] as? Double,
                let priceChange = json["change"] as? Double,
                let changePercent = json["changePercent"] as? Double else { return print("invalid JSON")}
            
            DispatchQueue.main.async { [weak self] in
                self?.displayStockInfo(companyName: companyName,
                                       companySymbol: companySymbol,
                                       price: price,
                                       priceChange: priceChange,
                                       changePercent: changePercent)
            }
        } catch {
            print("JSON parsing error: " + error.localizedDescription)
        }
    }
    
    private func displayStockInfo(companyName: String,
                                  companySymbol: String,
                                  price: Double,
                                  priceChange: Double,
                                  changePercent: Double) {
        
        activityIndicator.stopAnimating()
        companyNameLabel.text = companyName
        companySymbolLabel.text = companySymbol
        priceLabel.text = "\(price)"
        priceChangeLabel.text = "\(priceChange)"
        changePriceLabelColor(priceChange, changePercent)
        changeProc.text = String(format: "%.5f", changePercent * 100) + "%"
    }
    
    private func loadCompanyLogo(for symbol: String) {
        guard checkInternetConnection() else { return }
        
        let token = "pk_fec0f85ad8c44fe5863eb209e4f14106"
        guard let url = URL(string:"https://cloud.iexapis.com/stable/stock/\(symbol)/logo?token=\(token)") else {
            return
        }
        
        let dataTask = URLSession.shared.dataTask(with: url) { [weak self] (data, response, error) in
            guard let data = data, (response as? HTTPURLResponse)?.statusCode == 200, error == nil else {
                print("Network Error!")
                return
            }
            
            do {
                let jsonObject = try JSONSerialization.jsonObject(with: data)
                guard
                    let json = jsonObject as? [String: Any?],
                    let urlString = json["url"] as? String,
                    let companyLogoURL = URL(string: urlString) else { return print("invalid JSON")}
                
                DispatchQueue.main.async { [weak self] in
                    self?.displayStockLogo(companyLogoURL: companyLogoURL)
                }
                
            } catch {
                print("JSON parsing error: " + error.localizedDescription)
            }
        }
        dataTask.resume()
    }
    
    private func displayStockLogo(companyLogoURL: URL) {
        DispatchQueue.global().async {
            let data = try? Data(contentsOf: companyLogoURL)
            DispatchQueue.main.async { [weak self] in
                guard let data = data else { return }
                self?.logo.image = UIImage(data: data)
            }
        }
    }
    
    /// Изменяет цвет priceChangeLabel в зависимости от значения
    private func changePriceLabelColor(_ priceChange: Double, _ changePercent: Double) {
        if priceChange < 0 {
            priceChangeLabel.textColor = .red
        } else if priceChange > 0 {
            priceChangeLabel.textColor = .green
        } else {
            priceChangeLabel.textColor = .black
        }
        if changePercent < 0 {
            changeProc.textColor = .red
        } else if priceChange > 0 {
            changeProc.textColor = .green
        } else {
            changeProc.textColor = .black
        }
    }
}

// MARK: - UIPickerViewDataSource implementation

extension ViewController:UIPickerViewDataSource {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent: Int) -> Int {
        return companies.keys.count
    }
}

// MARK: - UIPickerViewDelegate implementation

extension ViewController: UIPickerViewDelegate {
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent: Int) -> String? {
        return Array(companies.keys)[row]
    }
    
    func pickerView(_ pickerView: UIPickerView,didSelectRow row: Int, inComponent component: Int) {
        requestQuoteUpdate()
    }
}

