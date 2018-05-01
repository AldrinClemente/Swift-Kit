//
// GameKitHelper.swift
//
// Copyright (c) 2016 Aldrin Clemente
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//

import Foundation
import GameKit


public typealias LeaderboardScore = Int
public typealias LeaderboardIdentifier = String
public typealias ScoreSubmissionHandler = (_ authenticated: Bool, _ error: Error?) -> Void
public typealias SaveGameDataHandler = (_ savedGame: GKSavedGame?, _ error: Error?) -> Void
public typealias FetchAllSavedGamesHandler = (_ savedGames: [GKSavedGame]?, _ error: Error?) -> Void
public typealias FetchSavedGameHandler = (_ savedGame: GKSavedGame?, _ error: Error?) -> Void
public typealias LoadGameDataHandler = (_ data: Data?, _ error: Error?) -> Void
public typealias DeleteGameDataHandler = (_ error: Error?) -> Void

public struct GameKitHelper {
    fileprivate static let GameKitHelperErrorDomain: String = "GameKitHelperErrorDomain"
    
    public static var player: GKLocalPlayer {
        return GKLocalPlayer.localPlayer()
    }
    
    fileprivate static let gameCenterControllerDelegate: GameCenterControllerDelegate = GameCenterControllerDelegate()
    
    public static func authenticateUser() {
        player.authenticateHandler = handleAuthentication
    }
}

extension GameKitHelper {
    static func handleAuthentication(_ viewController: UIViewController?, error: Error?) {
        if viewController != nil {
            print("Authenticating...")
            let vc = UIApplication.shared.keyWindow?.rootViewController
            vc?.present(
                viewController!,
                animated: true,
                completion: nil)
        }
        if error != nil {
            print(error?.localizedDescription as Any)
        }
    }
}

extension GameKitHelper {
    public static func submitScores(_ scores: [LeaderboardIdentifier : LeaderboardScore], completionHandler: ScoreSubmissionHandler? = nil) {
        var scoreArray: [GKScore] = []
        for (leaderboardId, scoreValue) in scores {
            let score = GKScore(leaderboardIdentifier: leaderboardId)
            score.value = Int64(scoreValue)
            scoreArray.append(score)
        }
        GKScore.report(scoreArray, withCompletionHandler: { error in
            completionHandler?(player.isAuthenticated, error)
        })
    }
    
    public static func showLeaderboards() {
        let viewController = GKGameCenterViewController()
        viewController.gameCenterDelegate = gameCenterControllerDelegate
        
        let vc = UIApplication.shared.keyWindow?.rootViewController
        vc?.present(
            viewController,
            animated: true,
            completion: nil)
    }
    
    open class GameCenterControllerDelegate: NSObject, GKGameCenterControllerDelegate {
        open func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
            gameCenterViewController.dismiss(animated: true, completion: nil)
        }
    }
}

extension GameKitHelper {
    public static func saveGameData(_ data: Data, name: String, completionHandler: SaveGameDataHandler? = nil) {
        player.saveGameData(data, withName: name, completionHandler: completionHandler)
    }
    
    public static func fetchAllSavedGameData(_ completionHandler: @escaping FetchAllSavedGamesHandler) {
        player.fetchSavedGames(completionHandler: completionHandler)
    }
    
    public static func fetchSavedGameData(_ name: String, completionHandler: @escaping FetchSavedGameHandler) {
        player.fetchSavedGames() { savedGames, error in
            if error != nil {
                completionHandler(nil, error as NSError?)
            } else {
                for savedGame in savedGames! {
                    if savedGame.name == name {
                        completionHandler(savedGame, nil)
                        return
                    }
                }
                completionHandler(nil, nil)
            }
        }
    }
    
    public static func loadGameData(_ savedGame: GKSavedGame, completionHandler: @escaping LoadGameDataHandler) {
        savedGame.loadData(completionHandler: completionHandler)
    }
    
    public static func loadGameData(_ name: String, completionHandler: @escaping LoadGameDataHandler) {
        fetchSavedGameData(name) { savedGame, error in
            if error != nil {
                completionHandler(nil, error)
            } else {
                if savedGame != nil {
                    loadGameData(savedGame!, completionHandler: completionHandler)
                } else {
                    completionHandler(nil, nil)
                }
            }
        }
    }
    
    public static func deleteGameData(_ name: String, completionHandler: @escaping DeleteGameDataHandler) {
        player.deleteSavedGames(withName: name, completionHandler: completionHandler)
    }
}
