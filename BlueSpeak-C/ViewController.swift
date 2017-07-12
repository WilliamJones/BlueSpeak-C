//
//  ViewController.swift
//  BlueSpeak-C
//
//  Created by William Jones on 7/10/17.
//  Copyright © 2017 ROKUBI,LLC. All rights reserved.
//

import UIKit
import CoreBluetooth
import AVFoundation

let bluespeakServiceUUIDString              = "1F1E5A17-4F18-4CAA-920A-167C97A0DE84"
let bluespeakServiceUUID                    = CBUUID(string: bluespeakServiceUUIDString)

let quoteServiceUUIDString                  = "2A8D7E46-E9CB-4E8F-ADF7-BC48BB9FA364"
let quoteServiceUUID                        = CBUUID(string: quoteServiceUUIDString)

let QUOTE_CHARACTERISTIC_GUID_STRING        = "94E35701-399A-40B5-9210-5AB129B88674"
let bluespeakCharacteristicUUID             = CBUUID(string: QUOTE_CHARACTERISTIC_GUID_STRING)

class ViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    var centralManager: CBCentralManager!
    var discoveredPeripheral: CBPeripheral!
    
    @IBOutlet weak var quoteTextField: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // create a CBPeripheralManager
                centralManager = CBCentralManager(delegate: self, queue: nil)
        // calls centralManagerDidUpdateState(_:)
    }
    
        func centralManagerDidUpdateState(_ central: CBCentralManager) {
            // check the state of Bluetooth on the device
            if (centralManager.state == .poweredOn){
                print("*** BLE powered on and ready ***")
                // scan for any peripheral with any service.
                // centralManager.scanForPeripherals(withServices: nil, options: nil)
                // calls centralManager(_:didDiscover:advertisementData:rssi)
                
                // scan for specific peripherals with specific services
                // use option [CBCentralManagerScanOptionAllowDuplicatesKey:true] to see each broudcast
                centralManager.scanForPeripherals(withServices:[bluespeakServiceUUID], options: nil)
            } else {
                print("*** BLE not on ***")
                return
            }
        }
    
        func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
            // a peripheral was discovered
            print("DidDiscover: \(peripheral)\n****************************")
            
            if discoveredPeripheral != peripheral {
                // Save a local copy of the peripheral, so CoreBluetooth doesn't get rid of it
                discoveredPeripheral = peripheral
                // connect central to peripheral
                centralManager.connect(peripheral, options: nil)
                // calls centralManager(_:didConnect)
            }
        }
    
        func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
            print("centralManager:didConnect peripheral()")
            print("DidConnect: \(peripheral)\n****************************")
            // Stop scanning now that we are connected to the peripheral
            centralManager.stopScan()
            // setup delegate
            peripheral.delegate = self
            peripheral.discoverServices(nil)
        }
    
        func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
            print("peripheral(_:didDiscoverServices)")
            
            if let error = error {
                print("error discovering services: \(error)")
                return
            }
            
            if let services = peripheral.services {
                print("Found \(services.count) services!\n****************************")
                
                for service in services {
                    //print("service: \(service)")
                    if service.uuid == quoteServiceUUID {
                        print("*** found BlueSpeak Service ***")
                        print("service: \(service)")
                        peripheral.discoverCharacteristics(nil, for: service)
                        // calls peripheral(_:didDiscoverCharacteristicsFor:error)
                    }
                }
            }
        }
    
        func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
            print("peripheral(_:didDiscoverCharacteristicsFor:error)")
            
            if let error = error {
                print("error discovering characteristics: \(error)")
                return
            }
            
            if let characteristics = service.characteristics {
                for characteristic in characteristics {
                    if characteristic.uuid == bluespeakCharacteristicUUID {
                        print("*** found BlueSpeak Characteristic ***")
                        print("UUID: \(characteristic.uuid)")
                        // subscribe to the characteristic
                        peripheral.setNotifyValue(true, for: characteristic)
                        // calls peripheral(_:didUpdateValueFor:error)
                    }
                }
            }
        }
    
        func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
            // the value that we subscribed to was updated
            print("peripheral(_:didUpdateValueFor:error)")
            
            if let error = error {
                print("error reading characteristic: \(error)")
                return
            }
            
            if let theValue = characteristic.value {
                if let theQuote = String(data: theValue, encoding: .utf8) {
                    print("Quote: \(theQuote)")
                    quoteTextField.text = theQuote
                    let speechSynthesizer = AVSpeechSynthesizer()
                    let speechUtterance: AVSpeechUtterance = AVSpeechUtterance(string: theQuote)
                    speechUtterance.voice = AVSpeechSynthesisVoice(language: "en-US")
                    speechSynthesizer.speak(speechUtterance)
                }
            }
        }
    
    func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
        //
    }
    
}

