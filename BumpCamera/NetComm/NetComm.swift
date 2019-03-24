//
//  NetComm.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 3/24/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit
import Network

//https://sosedoff.com/2018/03/23/zeroconf-swift.html
class NetComm: NSObject, NetServiceBrowserDelegate, NetServiceDelegate
{
    var NetBrowser: NetServiceBrowser!
    var Service: NetService?
    
    override init()
    {
        super.init()
        NetBrowser = NetServiceBrowser()
        NetBrowser.includesPeerToPeer = true
        NetBrowser.delegate = self
        
        Service = nil
        NetBrowser.stop()
        NetBrowser.searchForServices(ofType: "_http._tcp", inDomain: "")
    }
    
    func netServiceBrowserWillSearch(_ browser: NetServiceBrowser)
    {
        print("Search starting for Bonjour services.")
    }
    
    func netService(_ sender: NetService, didNotResolve errorDict: [String: NSNumber])
    {
        print("Resolve error: \(sender), \(errorDict)")
    }
    
    func netServiceBrowserDidStopSearch(_ browser: NetServiceBrowser)
    {
        print("Search stopped.")
    }
    
    func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool)
    {
        print("Discovered service.")
        print(" Service name: \(service.name)")
        print(" Service type: \(service.type)")
        print(" Service domain: \(service.domain)")
        service.delegate = self
        service.resolve(withTimeout: 5)
    }
    
    func netServiceDidResolveAddress(_ sender: NetService)
    {
        print("Resolved")
        if let ServiceIP = resolveIPv4(addresses: sender.addresses!)
        {
            print("Found IPV4: \(ServiceIP)")
        }
        else
        {
            print("Did not find IPV4.")
        }
        if let data = sender.txtRecordData()
        {
            let dict = NetService.dictionary(fromTXTRecord: data)
            if let value = String(data: dict["hello"]!, encoding: String.Encoding.utf8)
            {
            print("Hello=\(value)")
            }
        }
    }
    
    // Find an IPv4 address from the service address data
    func resolveIPv4(addresses: [Data]) -> String? {
        var result: String?
        
        for addr in addresses {
            let data = addr as NSData
            var storage = sockaddr_storage()
            data.getBytes(&storage, length: MemoryLayout<sockaddr_storage>.size)
            
            if Int32(storage.ss_family) == AF_INET {
                let addr4 = withUnsafePointer(to: &storage) {
                    $0.withMemoryRebound(to: sockaddr_in.self, capacity: 1) {
                        $0.pointee
                    }
                }
                
                if let ip = String(cString: inet_ntoa(addr4.sin_addr), encoding: .ascii) {
                    result = ip
                    break
                }
            }
        }
        
        return result
    }
}
