//
//  ContentController.swift
//  Rewatch
//
//  Created by Romain Pouclet on 2016-03-19.
//  Copyright © 2016 Perfectly-Cooked. All rights reserved.
//

import Foundation
import BetaSeriesKit
import ReactiveCocoa

protocol Show {
    var id: Int { get }
    var title: String { get }
}

protocol Episode {
    var id: Int { get }
    var title: String { get }
    var episode: Int { get }
    var season: Int { get }
    var summary: String { get }
}

protocol Member {
    var login: String { get }
    var avatar: NSURL? { get }
}

struct BetaseriesShow: Show {
    let wrappedShow: BetaSeriesKit.Show
    
    var id: Int {
        return wrappedShow.id
    }
    
    var title: String {
        return wrappedShow.title
    }
    
    init(wrappedShow: BetaSeriesKit.Show) {
        self.wrappedShow = wrappedShow
    }
}

struct BetaseriesEpisode: Episode {
    let wrappedEpisode: BetaSeriesKit.Episode
    
    init(wrappedEpisode: BetaSeriesKit.Episode) {
        self.wrappedEpisode = wrappedEpisode
    }
    
    var id: Int {
        return wrappedEpisode.id
    }
    
    var title: String {
        return wrappedEpisode.title
    }
    
    var episode: Int {
        return wrappedEpisode.episode
    }
    
    var season: Int {
        return wrappedEpisode.season
    }
    
    var summary: String {
        return wrappedEpisode.summary
    }
    
}

struct BetaSeriesMember: Member {
    let wrappedMember: BetaSeriesKit.Member

    init(wrappedMember: BetaSeriesKit.Member) {
        self.wrappedMember = wrappedMember
    }

    var login: String {
        return wrappedMember.login
    }

    var avatar: NSURL? {
        return wrappedMember.avatar
    }
}

enum ContentError: ErrorType {
    case ClientError
    case UnauthenticatedError
}

protocol ContentController {

    var rawLogin: String? { get }
    
    func fetchShows() -> SignalProducer<Show, ContentError>
    func fetchEpisodes(id: Int) -> SignalProducer<Episode, ContentError>
    func fetchPictureForEpisode(id: Int) -> SignalProducer<UIImage, ContentError>
    func fetchMemberInfos() -> SignalProducer<Member, ContentError>
}

class UnauthenticatedContentController: ContentController {
    
    var rawLogin: String? {
        return nil
    }
    
    func fetchEpisodes(id: Int) -> SignalProducer<Episode, ContentError> {
        return SignalProducer(error: .UnauthenticatedError)
    }
    
    func fetchShows() -> SignalProducer<Show, ContentError> {
        return SignalProducer(error: .UnauthenticatedError)
    }

    func fetchPictureForEpisode(id: Int) -> SignalProducer<UIImage, ContentError> {
        return SignalProducer(error: .UnauthenticatedError)
    }

    func fetchMemberInfos() -> SignalProducer<Member, ContentError> {
        return SignalProducer(error: .UnauthenticatedError)
    }
}

class BetaseriesContentController: ContentController {
    
    let authenticatedClient: AuthenticatedClient

    var rawLogin: String? {
        return authenticatedClient.token
    }

    init(authenticatedClient: AuthenticatedClient) {
        self.authenticatedClient = authenticatedClient
    }

    func fetchMemberInfos() -> SignalProducer<Member, ContentError> {
        return authenticatedClient
            .fetchMemberInfos()
            .map { member in BetaSeriesMember(wrappedMember: member) }
            .flatMapError { _ in return SignalProducer(error: ContentError.ClientError) }
    }

    func fetchEpisodes(id: Int) -> SignalProducer<Episode, ContentError> {
        let episodes = authenticatedClient
            .fetchEpisodes(id)
            .filter { $0.seen }
            .flatMapError { _ in return SignalProducer(error: ContentError.ClientError) }

        return episodes.map { episode in BetaseriesEpisode(wrappedEpisode: episode) }
    }
    
    func fetchShows() -> SignalProducer<Show, ContentError> {
        return authenticatedClient
            .fetchShows()
            .map { show in BetaseriesShow(wrappedShow: show) }
            .flatMapError { _ in return SignalProducer(error: ContentError.ClientError) }
    }

    func fetchPictureForEpisode(id: Int) -> SignalProducer<UIImage, ContentError> {
        return authenticatedClient
            .fetchImageForEpisode(id, width: 960, height: 960)
            .flatMapError { _ in return SignalProducer(error: ContentError.ClientError) }
    }

}