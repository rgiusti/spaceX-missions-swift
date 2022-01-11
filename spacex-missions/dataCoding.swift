//
//  dataCoding.swift
//  spacex-missions
//
//  Created by Rafael Giusti on 1/5/22.
//

import Foundation
import CoreData

struct LaunchesDocs: Decodable {
    let docs: [Launch]
    let totalDocs, limit, totalPages, page, pagingCounter: Int16
    let nextPage, prevPage, offset: Int16?
}

extension CodingUserInfoKey {
  static let managedObjectContext = CodingUserInfoKey(rawValue: "managedObjectContext")!
  static let relatedEntity = CodingUserInfoKey(rawValue: "relatedEntity")!
}

enum DecoderConfigurationError: Error {
  case missingManagedObjectContext
}

class Company: NSManagedObject, Decodable {
    enum CodingKeys: CodingKey{
        case name, founder, founded, employees, valuation, launch_sites
    }
    
    required convenience init(from decoder: Decoder) throws{
        
        guard let context = decoder.userInfo[CodingUserInfoKey.managedObjectContext] as? NSManagedObjectContext else {
              throw DecoderConfigurationError.missingManagedObjectContext
            }
        
        self.init(context: context)
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try container.decode(String.self, forKey: .name)
        self.founder = try container.decode(String.self, forKey: .founder)
        self.founded = try container.decode(Date.self, forKey: .founded)
        self.employees = try container.decode(Int32.self, forKey: .employees)
        self.launchSites = try container.decode(Int16.self, forKey: .launch_sites)
        self.valuation = NSDecimalNumber(decimal: try container.decode(Decimal.self, forKey: .valuation))
        
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
    }
}

class Launch: NSManagedObject, Decodable {
    enum CodingKeys: CodingKey{
        case date_local, success, name, rocket, links
    }
    enum rocketKeys: CodingKey {
        case name, type
    }
    enum linkKeys: CodingKey{
        case youtube_id, webcast, wikipedia, article, patch
    }
    enum patchKeys: CodingKey{
        case small, large
    }
    
    required convenience init(from decoder: Decoder) throws{
        guard let context = decoder.userInfo[CodingUserInfoKey.managedObjectContext] as? NSManagedObjectContext else {
              throw DecoderConfigurationError.missingManagedObjectContext
            }
        
        self.init(context: context)
        
        if let company = decoder.userInfo[CodingUserInfoKey.relatedEntity] as? Company {
            self.parentCompany = company
        }else {
            print("Empty parent company")
        }
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.missionName = try container.decode(String.self, forKey: .name)
        if let rocketNode = try? container.nestedContainer(keyedBy: rocketKeys.self, forKey: .rocket) {
            self.rocketName = try rocketNode.decode(String.self, forKey: .name)
            self.rocketType = try rocketNode.decode(String.self, forKey: .type)
        }
        if let launchSuccessDecoded = try? container.decode(Bool.self, forKey: .success) {
            self.launchSuccess = launchSuccessDecoded
        }
        let isoDatetime = try container.decode(String.self, forKey: .date_local)
        self.datetime = ISO8601DateFormatter().date(from:isoDatetime)
        
        if let linksContainer = try? container.nestedContainer(keyedBy: linkKeys.self, forKey: .links) {
        
            if let patchContainer = try? linksContainer.nestedContainer(keyedBy: patchKeys.self, forKey: .patch){
                self.patchImg = try? patchContainer.decode(URL.self, forKey: .small)
            }
            
            self.article = try? linksContainer.decode(URL.self, forKey: .article)
            self.wikipedia = try? linksContainer.decode(URL.self, forKey: .wikipedia)
            self.webcast = try? linksContainer.decode(URL.self, forKey: .webcast)
            self.youtubeId = try? linksContainer.decode(String.self, forKey: .youtube_id)
        }

    }
}

