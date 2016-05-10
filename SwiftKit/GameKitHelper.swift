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
public typealias ScoreSubmissionHandler = (authenticated: Bool, error: NSError?) -> Void
public typealias SaveGameDataHandler = (savedGame: GKSavedGame?, error: NSError?) -> Void
public typealias FetchAllSavedGamesHandler = (savedGames: [GKSavedGame]?, error: NSError?) -> Void
public typealias FetchSavedGameHandler = (savedGame: GKSavedGame?, error: NSError?) -> Void
public typealias LoadGameDataHandler = (data: NSData?, error: NSError?) -> Void
public typealias DeleteGameDataHandler = (error: NSError?) -> Void

public struct GameKitHelper {
    private static let GameKitHelperErrorDomain: String = "GameKitHelperErrorDomain"
    
    public static var player: GKLocalPlayer {
        return GKLocalPlayer.localPlayer()
    }
    
    private static let gameCenterControllerDelegate: GameCenterControllerDelegate = GameCenterControllerDelegate()
    
    public static func authenticateUser() {
        player.authenticateHandler = handleAuthentication
    }
}

extension GameKitHelper {
    static func handleAuthentication(viewController: UIViewController?, error: NSError?) {
        if viewController != nil {
            print("Authenticating...")
            let vc = UIApplication.sharedApplication().keyWindow?.rootViewController
            vc?.presentViewController(
                viewController!,
                animated: true,
                completion: nil)
        }
        if error != nil {
            print(error?.localizedDescription)
        }
    }
}

extension GameKitHelper {
    public static func submitScores(scores: [LeaderboardIdentifier : LeaderboardScore], completionHandler: ScoreSubmissionHandler? = nil) {
        var scoreArray: [GKScore] = []
        for (leaderboardId, scoreValue) in scores {
            let score = GKScore(leaderboardIdentifier: leaderboardId)
            score.value = Int64(scoreValue)
            scoreArray.append(score)
        }
        GKScore.reportScores(scoreArray) { error in
            completionHandler?(authenticated: player.authenticated, error: error)
        }
    }
    
    public static func showLeaderboards() {
        let viewController = GKGameCenterViewController()
        viewController.gameCenterDelegate = gameCenterControllerDelegate
        
        let vc = UIApplication.sharedApplication().keyWindow?.rootViewController
        vc?.presentViewController(
            viewController,
            animated: true,
            completion: nil)
    }
    
    public class GameCenterControllerDelegate: NSObject, GKGameCenterControllerDelegate {
        public func gameCenterViewControllerDidFinish(gameCenterViewController: GKGameCenterViewController) {
            gameCenterViewController.dismissViewControllerAnimated(true, completion: nil)
        }
    }
}

extension GameKitHelper {
    public static func saveGameData(data: NSData, name: String, completionHandler: SaveGameDataHandler? = nil) {
        player.saveGameData(data, withName: name, completionHandler: completionHandler)
    }
    
    public static func fetchAllSavedGameData(completionHandler: FetchAllSavedGamesHandler) {
        player.fetchSavedGamesWithCompletionHandler(completionHandler)
    }
    
    public static func fetchSavedGameData(name: String, completionHandler: FetchSavedGameHandler) {
        player.fetchSavedGamesWithCompletionHandler() { savedGames, error in
            if error != nil {
                completionHandler(savedGame: nil, error: error)
            } else {
                for savedGame in savedGames! {
                    if savedGame.name == name {
                        completionHandler(savedGame: savedGame, error: nil)
                        return
                    }
                }
                completionHandler(savedGame: nil, error: nil)
            }
        }
    }
    
    public static func loadGameData(savedGame: GKSavedGame, completionHandler: LoadGameDataHandler) {
        savedGame.loadDataWithCompletionHandler(completionHandler)
    }
    
    public static func loadGameData(name: String, completionHandler: LoadGameDataHandler) {
        fetchSavedGameData(name) { savedGame, error in
            if error != nil {
                completionHandler(data: nil, error: error)
            } else {
                if savedGame != nil {
                    loadGameData(savedGame!, completionHandler: completionHandler)
                } else {
                    completionHandler(data: nil, error: nil)
                }
            }
        }
    }
    
    public static func deleteGameData(name: String, completionHandler: DeleteGameDataHandler) {
        player.deleteSavedGamesWithName(name, completionHandler: completionHandler)
    }
}