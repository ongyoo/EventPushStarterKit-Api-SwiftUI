//
//  Domain.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 17/10/2569 BE.
//

// Domain layer: what the business is, independent of UI, network and database.
//
// Add one group per business area:
//
//   Domain/<Area>/Entities/       public models (structs, enums), value objects
//   Domain/<Area>/UseCases/       business rules shared by screens
//   Domain/<Area>/Repositories/   protocols + Container keys (implemented in DataLayer)
//
// See docs/ARCHITECTURE.md and the EventPush sample (Domain/Event).
