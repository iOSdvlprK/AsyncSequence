import UIKit

class BitcoinPriceMonitor {
    var price: Double = 0.0
    var timer: Timer?
    var priceHandler: (Double) -> Void = { _ in }
    
    @objc func getPrice() {
        priceHandler(Double.random(in: 20000...40000))
    }
    
    func startUpdating() {
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(getPrice), userInfo: nil, repeats: true)
    }
    
    func stopUpdating() {
        timer?.invalidate()
    }
}

/*
let bitcoinPriceMonitor = BitcoinPriceMonitor()
bitcoinPriceMonitor.priceHandler = {
    print($0)
}

bitcoinPriceMonitor.startUpdating() */

let bitcoinPriceStream = AsyncStream<Double> { continuation in
    let bitcoinPriceMonitor = BitcoinPriceMonitor()
    bitcoinPriceMonitor.priceHandler = {
        continuation.yield($0)
    }
    
    continuation.onTermination = { @Sendable termination in
        switch termination {
        case .finished:
            print("Bitcoin price monitoring stream finished.")
        case .cancelled:
            print("Bitcoin price monitoring stream cancelled.")
        }
        bitcoinPriceMonitor.stopUpdating()
    }
    
    bitcoinPriceMonitor.startUpdating()
}

Task {
    for await bitcoinPrice in bitcoinPriceStream {
        print(bitcoinPrice)
    }
    
    // Finish the stream after 5 seconds
    try await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds
    throw CancellationError()
}
