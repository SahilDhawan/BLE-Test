import UIKit
import CoreBluetooth


class HRMViewController: UIViewController {
  // Detail regarding connection process of central device can be found here: https://developer.apple.com/library/archive/documentation/NetworkingInternetWeb/Conceptual/CoreBluetooth_concepts/PerformingCommonCentralRoleTasks/PerformingCommonCentralRoleTasks.html#//apple_ref/doc/uid/TP40013257-CH3-SW1
  
  // Details regarding basic roles of peripheral can be found here: https://developer.apple.com/library/archive/documentation/NetworkingInternetWeb/Conceptual/CoreBluetooth_concepts/PerformingCommonPeripheralRoleTasks/PerformingCommonPeripheralRoleTasks.html#//apple_ref/doc/uid/TP40013257-CH4-SW1
  
  var centralManager: CBCentralManager!
  var connectedPeripherals: [CBPeripheral] = []
  
  let heartRateServiceCBUUID = CBUUID(string: "0x180D")
  
  let heartRateMeasurementCharacteristicCBUUID = CBUUID(string: "2A37")
  let bodySensorLocationCharacteristicCBUUID = CBUUID(string: "2A38")
  let heartRateControlPointCharacteristicCBUUID = CBUUID(string: "2A39")
  
  override func viewDidLoad() {
    super.viewDidLoad()
    // MARK: - 1) Initialize Central Manager, it represents the iOS device
    // This will call centralManagerDidUpdateState delegate method
    centralManager = CBCentralManager(delegate: self, queue: nil)
  }
}

extension HRMViewController: CBCentralManagerDelegate {
  func centralManagerDidUpdateState(_ central: CBCentralManager) {
    switch central.state {
    case .unknown:
      print("central.state is .unknown")
    case .resetting:
      print("central.state is .resetting")
    case .unsupported:
      print("central.state is .unsupported")
    case .unauthorized:
      print("central.state is .unauthorized")
    case .poweredOff:
      print("central.state is .poweredOff")
      
    case .poweredOn:
      print("central.state is .poweredOn")
      // MARK: - 2) Start scanning for Peripherals
      // Here we are specifically looking for peripherals with Heart Rate service
      // We can change the UUID to look for peripherals with other services
      // Or we can set it to nil and get all peripherals around
      // This will call didDiscover delegate method
      centralManager.scanForPeripherals(withServices: [heartRateServiceCBUUID])
    }
  }
  
  // MARK: - 3) Here we get a reference to the peripheral
  // Now we stop scanning other for other peripherals
  // And connect centralManager to heartRatePeripheral
  // This will call didConnect delegate method
  func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
    print("found peripheral: \(peripheral)")
    peripheral.delegate = self
    connectedPeripherals.append(peripheral)
    centralManager.connect(peripheral)
  }

  
  // MARK: - 4) Here the iOS device as a central and the Heart Rate sensor as a peripheral are connected
  // Now we discover the Heart Rate Service in the Peripheral
  // We can discover all available services by setting the array to nil
  // This will call didDiscoverServices delegate method
  func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
    print("Connected with peripheral: \(peripheral)")
    peripheral.discoverServices([heartRateServiceCBUUID])
  }
}

extension HRMViewController: CBPeripheralDelegate {
  
  // MARK: - 5) Here we get an array that has one element which is Hate Rate service
  // Now we discover all characteristics in the Hate Rate service
  // This will call didDiscoverCharacteristicsFor delegate method
  func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
    
    guard let services = peripheral.services else { return }
    
    for service in services {
      peripheral.discoverCharacteristics(nil, for: service)
    }
  }
  
  
  // MARK: - 6) Here we get 2 Characteristics:
  // 1. Body Location Characteristic: has read property for one time read
  // 2. Heart Rate Measurement Characteristic: has notify property, to notify the iOS device every time the heart rate changes
  // Now we read the value of each characteristic
  // This will update didUpdateValueFor delegate method
  func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
    
    guard let characteristics = service.characteristics else { return }
    
    for characteristic in characteristics {
      print("Found characteristics: \(characteristic) for peripheral: \(peripheral)")
      
      // Body Location Characteristic
      if characteristic.properties.contains(.read) {
        print("\(characteristic.uuid): properties contains .read")
        peripheral.readValue(for: characteristic)
      }
      
      if characteristic.properties.contains(.write) {
        print("\(characteristic.uuid): properties contains .write")
        let data = "Test write data".data(using: .utf8)!
        peripheral.writeValue(data, for: characteristic, type: .withResponse)
      }
    }
  }
  
  
  // MARK: - 7) Here we get the value of the Body Location one time & the value of Heart Rate every notification
  // So we read the characteristic value and show it on the corresponding Label
  func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic,
                  error: Error?) {
    switch characteristic.uuid {
    case bodySensorLocationCharacteristicCBUUID:
      let bodySensorLocation = bodyLocation(from: characteristic)
      print("Received value: \(bodySensorLocation) for read characteristic for peripheral: \(peripheral)")
    case heartRateMeasurementCharacteristicCBUUID:
      print("Notified value: \(characteristic) for heard rate for peripheral:\(peripheral)")
    default:
      print("Unhandled Characteristic UUID: \(characteristic.uuid)")
    }
  }
  
  // MARK: - 8) Here we get the acknowledgment for writing value of heart control to peripheral
  func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
      print("Received acknowledgment for writing to peripheral: \(peripheral)")
  }
}


// MARK: - Helper Functions
extension HRMViewController {
  private func bodyLocation(from characteristic: CBCharacteristic) -> String {
    guard let characteristicData = characteristic.value,
          let byte = characteristicData.first else { return "Error" }
    
    switch byte {
    case 0: return "Other"
    case 1: return "Chest"
    case 2: return "Wrist"
    case 3: return "Finger"
    case 4: return "Hand"
    case 5: return "Ear Lobe"
    case 6: return "Foot"
    default:
      return "Reserved for future use"
    }
  }
}
