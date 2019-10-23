import UIKit
import CoreNFC

class ViewController: UIViewController, FeliCaReaderDelegate {
    @IBOutlet weak var imageView: UIImageView!

    var reader: FeliCaReader?
    
    func readerDidBecomeActive(_ reader: FeliCaReader) {
        
    }
    
    func feliCaReader(_ reader: FeliCaReader, withError error: Error) {
        guard let error = error as? FeliCaTagError else {
            return
        }
        
        switch error {
        case .cannotConnect:
            reader.session?.invalidate(errorMessage: "無法與 FeliCa 連接")
        case .countExceed:
            reader.session?.invalidate(errorMessage: "同時偵測出超過 2 張卡片，請移除後再試")
        case .serviceCodeNotSet:
            reader.session?.invalidate(errorMessage: "service code 未設定")
        case .serviceCodeUnavailable:
            reader.session?.invalidate(errorMessage: "service code 無法使用")
        case .statusError:
            reader.session?.invalidate(errorMessage: "FeliCa 狀態錯誤")
        case .typeMismatch:
            reader.session?.invalidate(errorMessage: "卡片非 FeliCa 類型")
        case .userCancel: break
        case .becomeInvalidate: break
        }
    }
    
    func feliCaReader(_ reader: FeliCaReader, didRead card: FeliCaCard) {
        self.reader?.session?.invalidate()
        DispatchQueue.main.async {
            let vc = self.storyboard?.instantiateViewController(withIdentifier: "cardTable") as! CardTableViewController
            vc.card = card
            self.showDetailViewController(vc, sender: nil)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        imageView.image = UIImage(named: "reader")
    }

  
    @IBAction func tapScan(_ sender: UIButton) {
        self.reader = FeliCaReader(delegate: self)
        self.reader?.read([
            .entryExitHistory
        ], blocks: 10)
    }
    
    
}
